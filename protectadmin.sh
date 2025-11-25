#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PANEL_PATH="/var/www/pterodactyl"
BACKUP_DIR="/root/pterodactyl_backup_$(date +%Y%m%d_%H%M%S)"

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "Script ini harus dijalankan sebagai root!"
        exit 1
    fi
}

# Check if Pterodactyl directory exists
check_panel_directory() {
    if [ ! -d "$PANEL_PATH" ]; then
        log_error "Directory Pterodactyl tidak ditemukan di $PANEL_PATH"
        log_info "Jika panel berada di lokasi lain, edit variabel PANEL_PATH di script"
        exit 1
    fi
}

# Backup existing files
backup_files() {
    log_info "Membuat backup files ke $BACKUP_DIR..."
    mkdir -p "$BACKUP_DIR"

    cp "$PANEL_PATH/app/Http/Controllers/Admin/Settings/IndexController.php" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$PANEL_PATH/routes/admin.php" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$PANEL_PATH/app/Http/Kernel.php" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$PANEL_PATH/resources/views/admin/settings/index.blade.php" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$PANEL_PATH/app/Http/Controllers/Admin/ServersController.php" "$BACKUP_DIR/" 2>/dev/null || true

    log_success "Backup files selesai"
}

# Backup database
backup_database() {
    log_info "Membuat backup database..."
    if command -v mysqldump &> /dev/null; then
        # Attempt to dump 'pterodactyl' database; prompt for password interactively
        if mysqldump -u root -p pterodactyl > "$BACKUP_DIR/pterodactyl_backup.sql" 2>/dev/null; then
            log_success "Backup database selesai"
        else
            log_warning "Gagal backup database, lanjut tanpa backup DB (cek credential mysqldump)"
        fi
    else
        log_warning "mysqldump tidak ditemukan, lanjut tanpa backup DB"
    fi
}

# Create migration file (creates two columns on settings table)
create_migration() {
    log_info "Membuat migration file..."

    ts=$(date +%Y_%m_%d_%H%M%S)
    mig="$PANEL_PATH/database/migrations/${ts}_add_menu_protection_settings.php"
    cat > "$mig" << 'EOF'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddMenuProtectionSettings extends Migration
{
    public function up()
    {
        if (!Schema::hasTable('settings')) {
            return;
        }

        Schema::table('settings', function (Blueprint $table) {
            if (!Schema::hasColumn('settings', 'menu_protection_enabled')) {
                $table->boolean('menu_protection_enabled')->default(false);
            }
            if (!Schema::hasColumn('settings', 'menu_protection_message')) {
                $table->text('menu_protection_message')->nullable();
            }
        });
    }

    public function down()
    {
        if (!Schema::hasTable('settings')) {
            return;
        }

        Schema::table('settings', function (Blueprint $table) {
            if (Schema::hasColumn('settings', 'menu_protection_enabled')) {
                $table->dropColumn('menu_protection_enabled');
            }
            if (Schema::hasColumn('settings', 'menu_protection_message')) {
                $table->dropColumn('menu_protection_message');
            }
        });
    }
}
EOF

    log_success "Migration file created: $mig"
}

# Route handling: DO NOT add new route by default to avoid duplicate route names.
add_route() {
    log_info "Menangani route proteksi menu (safe-check)..."

    ROUTE_FILE="$PANEL_PATH/routes/admin.php"
    if [ ! -f "$ROUTE_FILE" ]; then
        log_warning "routes/admin.php tidak ditemukan, tidak ada perubahan route."
        return
    fi

    if grep -q "admin.settings.menu-protection" "$ROUTE_FILE" || grep -q "/settings/menu-protection" "$ROUTE_FILE"; then
        log_info "Route proteksi menu sudah ada di routes/admin.php — tidak menambahkan apa-apa."
        return
    fi

    # Instead of adding a new route, we'll rely on existing Admin Settings update route.
    # If you really need a dedicated route, enable below (commented) block after manual review.
    log_info "Tidak menambahkan route baru. View akan disisipkan agar submit ke route 'admin.settings' yang sudah ada."
}

# Create middleware file (if not exists)
create_middleware() {
    log_info "Membuat middleware (jika belum ada)..."

    MW_DIR="$PANEL_PATH/app/Http/Middleware"
    MW_FILE="$MW_DIR/CheckServerOwnership.php"
    mkdir -p "$MW_DIR"

    if [ -f "$MW_FILE" ]; then
        log_info "Middleware CheckServerOwnership sudah ada, skip pembuatan."
        return
    fi

    cat > "$MW_FILE" << 'EOF'
<?php

namespace Pterodactyl\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Pterodactyl\Models\Server;
use Pterodactyl\Models\Setting;
use Symfony\Component\HttpKernel\Exception\AccessDeniedHttpException;

class CheckServerOwnership
{
    public function handle(Request $request, Closure $next)
    {
        try {
            $settings = Setting::first();
        } catch (\Exception $e) {
            $settings = null;
        }

        // Skip if settings not found or protection disabled or user is root admin
        if (!$settings || !($settings->menu_protection_enabled ?? false) || ($request->user() && $request->user()->root_admin)) {
            return $next($request);
        }

        $serverId = $this->getServerIdFromRequest($request);

        if ($serverId) {
            $server = Server::find($serverId);

            if ($server && $server->owner_id !== ($request->user()->id ?? null)) {
                $message = $settings->menu_protection_message ?? 'Anda tidak memiliki akses ke server ini.';
                throw new AccessDeniedHttpException($message);
            }
        }

        return $next($request);
    }

    private function getServerIdFromRequest(Request $request)
    {
        if ($request->route('server')) {
            return $request->route('server');
        }

        if ($request->route('id')) {
            return $request->route('id');
        }

        // try common params
        if ($request->route('server_id')) {
            return $request->route('server_id');
        }

        return null;
    }
}
EOF

    log_success "Middleware berhasil dibuat (atau sudah ada)."
}

# Register middleware in Kernel if missing
register_middleware() {
    log_info "Mendaftarkan middleware ke Kernel (jika belum terdaftar)..."

    KERNEL="$PANEL_PATH/app/Http/Kernel.php"
    if [ ! -f "$KERNEL" ]; then
        log_warning "Kernel.php tidak ditemukan, skip pendaftaran middleware."
        return
    fi

    # Backup kernel
    cp "$KERNEL" "$KERNEL.backup" 2>/dev/null || true

    # Only add the middleware registration if not present
    if grep -q "server.ownership" "$KERNEL"; then
        log_info "Middleware sudah terdaftar di Kernel, skip."
        return
    fi

    # Insert registration into $routeMiddleware array
    # We will attempt to insert after the protected $routeMiddleware line.
    awk '
    BEGIN{added=0}
    {
        print $0
        if (!added && $0 ~ /protected \$routeMiddleware = \[/) {
            print "        '\''server.ownership'\'' => \\\\Pterodactyl\\\\Http\\\\Middleware\\\\CheckServerOwnership::class,"
            added=1
        }
    }
    ' "$KERNEL" > "$KERNEL.new" && mv "$KERNEL.new" "$KERNEL"

    log_success "Middleware telah didaftarkan (jika struktur Kernel cocok)."
}

# Modify settings view: insert protection fields into existing settings index view
modify_settings_view() {
    log_info "Memodifikasi settings view..."

    VIEW="$PANEL_PATH/resources/views/admin/settings/index.blade.php"
    if [ ! -f "$VIEW" ]; then
        log_warning "View settings tidak ditemukan di $VIEW, skip modifikasi view."
        return
    fi

    cp "$VIEW" "$VIEW.backup" 2>/dev/null || true

    if grep -q "Proteksi Menu" "$VIEW"; then
        log_info "Section Proteksi Menu sudah ada, skip modifikasi view"
        return
    fi

    # Create the block to insert
    read -r -d '' BLOCK <<'EOB'
    <!-- Proteksi Menu Section -->
    <div class="box box-primary">
        <div class="box-header with-border">
            <h3 class="box-title">
                <i class="fa fa-shield"></i> Proteksi Menu
            </h3>
        </div>
        <div class="box-body">
            <div class="form-group">
                <label for="menu_protection_enabled">Aktifkan Proteksi Anti-Intip</label>
                <div>
                    <input type="checkbox" name="menu_protection_enabled" id="menu_protection_enabled"
                           value="1" {{ old('menu_protection_enabled', $settings->get('menu_protection_enabled')) ? 'checked' : '' }}>
                    <p class="text-muted small">
                        Jika diaktifkan, admin hanya dapat melihat server yang mereka buat sendiri.
                    </p>
                </div>
            </div>

            <div class="form-group">
                <label for="menu_protection_message">Pesan Proteksi</label>
                <textarea name="menu_protection_message" id="menu_protection_message"
                          class="form-control" rows="3"
                          placeholder="Masukkan pesan yang akan ditampilkan ketika admin mencoba mengintip server lain">{{ old('menu_protection_message', $settings->get('menu_protection_message')) }}</textarea>
                <p class="text-muted small">
                    Pesan ini akan ditampilkan ketika admin mencoba mengakses server yang bukan miliknya.
                </p>
            </div>
        </div>
    </div>
EOB

    # Insert BLOCK before the last occurrence of </form>
    awk -v block="$BLOCK" '
    { lines[NR] = $0 }
    END {
        idx = -1
        for (i=NR; i>=1; i--) {
            if (lines[i] ~ /<\/form>/) { idx = i; break }
        }
        if (idx == -1) {
            # no form found — append at the end
            for (i=1; i<=NR; i++) print lines[i]
            print block
        } else {
            for (i=1; i<idx; i++) print lines[i]
            print block
            for (i=idx; i<=NR; i++) print lines[i]
        }
    }' "$VIEW" > "$VIEW.new" && mv "$VIEW.new" "$VIEW"

    log_success "Settings view berhasil dimodifikasi (index view)."
}

# Run migrations and optimizations
run_optimizations() {
    log_info "Menjalankan migration dan optimizations..."

    cd "$PANEL_PATH" || { log_error "Gagal masuk ke $PANEL_PATH"; return; }

    # Run migration (if any)
    if command -v php &> /dev/null; then
        php artisan migrate --force || log_warning "php artisan migrate gagal (cek migrasi)."

        # Clear caches safely
        php artisan config:clear || true
        php artisan config:cache || true
        php artisan route:clear || true
        php artisan view:clear || true
    else
        log_warning "PHP tidak ditemukan di PATH, skip artisan commands."
    fi

    # Set permissions
    if id www-data &> /dev/null; then
        chown -R www-data:www-data "$PANEL_PATH"/ || true
    fi
    chmod -R 755 "$PANEL_PATH"/ || true
    chmod -R 755 "$PANEL_PATH"/storage || true

    log_success "Optimizations selesai"
}

# Restart services
restart_services() {
    log_info "Restarting services..."

    # Restart queue worker
    if systemctl list-units --type=service --all | grep -q pteroq; then
        systemctl restart pteroq || log_warning "Tidak dapat restart pteroq"
    fi

    # Reload web server
    systemctl reload nginx 2>/dev/null || systemctl reload apache2 2>/dev/null || true

    log_success "Services berhasil di-restart (jika tersedia)"
}

# Main installation function
install_protection() {
    log_info "Memulai instalasi fitur Proteksi Menu..."

    check_root
    check_panel_directory
    backup_files
    backup_database
    create_migration
    add_route
    create_middleware
    register_middleware
    modify_settings_view
    run_optimizations
    restart_services

    log_success "🎉 Instalasi fitur Proteksi Menu selesai!"
    log_info "📍 Lokasi backup: $BACKUP_DIR"
    log_info "🔧 Cara penggunaan:"
    log_info "   1. Login sebagai Admin ID 1"
    log_info "   2. Pergi ke Admin → Settings"
    log_info "   3. Scroll ke bagian 'Proteksi Menu'"
    log_info "   4. Aktifkan fitur dan atur pesan"
    log_info "   5. Save settings"
}

# Uninstall function (informational)
uninstall_protection() {
    log_warning "Fitur uninstall belum diimplementasikan secara otomatis."
    log_info "Anda dapat restore manual dari backup di: $BACKUP_DIR"
}

# Show usage
show_usage() {
    echo -e "${BLUE}Pterodactyl Menu Protection Installer (Fixed)${NC}"
    echo "Usage: $0 [option]"
    echo ""
    echo "Options:"
    echo "  install     - Install menu protection feature"
    echo "  uninstall   - Uninstall menu protection feature"
    echo "  help        - Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 install    # Install the feature"
    echo "  $0 help       # Show help"
}

# Main script
case "${1:-}" in
    install)
        install_protection
        ;;
    uninstall)
        uninstall_protection
        ;;
    help|--help|-h)
        show_usage
        ;;
    *)
        log_error "Perintah tidak valid!"
        echo ""
        show_usage
        exit 1
        ;;
esac
