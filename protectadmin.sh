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
    
    cp "$PANEL_PATH/app/Http/Controllers/Admin/SettingsController.php" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$PANEL_PATH/routes/admin.php" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$PANEL_PATH/app/Http/Kernel.php" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$PANEL_PATH/resources/views/admin/settings.blade.php" "$BACKUP_DIR/" 2>/dev/null || true
    cp "$PANEL_PATH/app/Http/Controllers/Admin/ServersController.php" "$BACKUP_DIR/" 2>/dev/null || true
    
    log_success "Backup files selesai"
}

# Backup database
backup_database() {
    log_info "Membuat backup database..."
    if command -v mysqldump &> /dev/null; then
        if mysqldump -u root -p pterodactyl > "$BACKUP_DIR/pterodactyl_backup.sql" 2>/dev/null; then
            log_success "Backup database selesai"
        else
            log_warning "Gagal backup database, lanjut tanpa backup DB"
        fi
    else
        log_warning "mysqldump tidak ditemukan, lanjut tanpa backup DB"
    fi
}

# Create migration file
create_migration() {
    log_info "Membuat migration file..."
    
    cat > "$PANEL_PATH/database/migrations/$(date +%Y_%m_%d_%H%M%S)_add_menu_protection_settings.php" << 'EOF'
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

class AddMenuProtectionSettings extends Migration
{
    public function up()
    {
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
        Schema::table('settings', function (Blueprint $table) {
            $table->dropColumn(['menu_protection_enabled', 'menu_protection_message']);
        });
    }
}
EOF
    log_success "Migration file created"
}

# Add route to admin.php
add_route() {
    log_info "Menambahkan route..."
    
    # Backup original routes file
    cp "$PANEL_PATH/routes/admin.php" "$PANEL_PATH/routes/admin.php.backup"
    
    # Add route before the closing });
    sed -i '/^});$/i \
// Menu Protection Route\
Route::post('\''/settings/menu-protection'\'', '\''Admin\\\SettingsController@updateMenuProtection'\'')->name('\''admin.settings.menu-protection'\'');' "$PANEL_PATH/routes/admin.php"
    
    log_success "Route berhasil ditambahkan"
}

# Create middleware
create_middleware() {
    log_info "Membuat middleware..."
    
    cat > "$PANEL_PATH/app/Http/Middleware/CheckServerOwnership.php" << 'EOF'
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
        $settings = Setting::first();
        
        // Skip jika proteksi tidak aktif atau user adalah root admin
        if (!$settings || !$settings->menu_protection_enabled || $request->user()->root_admin) {
            return $next($request);
        }
        
        $serverId = $this->getServerIdFromRequest($request);
        
        if ($serverId) {
            $server = Server::find($serverId);
            
            if ($server && $server->owner_id !== $request->user()->id) {
                $message = $settings->menu_protection_message ?: 'Anda tidak memiliki akses ke server ini.';
                throw new AccessDeniedHttpException($message);
            }
        }

        return $next($request);
    }

    private function getServerIdFromRequest(Request $request)
    {
        // Ambil server ID dari berbagai route pattern
        if ($request->route('server')) {
            return $request->route('server');
        }
        
        if ($request->route('id')) {
            return $request->route('id');
        }
        
        return null;
    }
}
EOF
    log_success "Middleware berhasil dibuat"
}

# Register middleware in Kernel
register_middleware() {
    log_info "Mendaftarkan middleware..."
    
    # Backup kernel
    cp "$PANEL_PATH/app/Http/Kernel.php" "$PANEL_PATH/app/Http/Kernel.php.backup"
    
    # Add to routeMiddleware array
    sed -i "/protected \$routeMiddleware = \[/a \
        'server.ownership' => \\\\Pterodactyl\\\\Http\\\\Middleware\\\\CheckServerOwnership::class," "$PANEL_PATH/app/Http/Kernel.php"
    
    log_success "Middleware berhasil didaftarkan"
}

# Modify SettingsController
modify_settings_controller() {
    log_info "Memodifikasi SettingsController..."
    
    # Backup controller
    cp "$PANEL_PATH/app/Http/Controllers/Admin/SettingsController.php" "$PANEL_PATH/app/Http/Controllers/Admin/SettingsController.php.backup"
    
    # Check if the method already exists
    if grep -q "updateMenuProtection" "$PANEL_PATH/app/Http/Controllers/Admin/SettingsController.php"; then
        log_info "Method updateMenuProtection sudah ada, skip modifikasi controller"
        return
    fi
    
    # Add the method before the last closing brace
    sed -i '/^}$/i \
\
    /**\
     * Update menu protection settings.\
     */\
    public function updateMenuProtection(Request $request): RedirectResponse\
    {\
        $settings = Setting::first();\
        \
        $settings->update([\
            '\''menu_protection_enabled'\'' => $request->input('\''menu_protection_enabled'\'', false),\
            '\''menu_protection_message'\'' => $request->input('\''menu_protection_message'\'', '\''Anda tidak memiliki akses ke server ini.'\''),\
        ]);\
\
        $this->alert->success('\''Pengaturan proteksi menu berhasil disimpan.'\'')->flash();\
\
        return redirect()->route('\''admin.settings'\'');\
    }' "$PANEL_PATH/app/Http/Controllers/Admin/SettingsController.php"
    
    log_success "SettingsController berhasil dimodifikasi"
}

# Modify settings view
modify_settings_view() {
    log_info "Memodifikasi settings view..."
    
    # Backup view
    cp "$PANEL_PATH/resources/views/admin/settings.blade.php" "$PANEL_PATH/resources/views/admin/settings.blade.php.backup"
    
    # Check if the protection section already exists
    if grep -q "Proteksi Menu" "$PANEL_PATH/resources/views/admin/settings.blade.php"; then
        log_info "Section Proteksi Menu sudah ada, skip modifikasi view"
        return
    fi
    
    # Create temporary file with the new content
    cat > /tmp/protection_section.blade.php << 'EOF'

    <!-- Proteksi Menu Section -->
    <div class="box box-primary">
        <div class="box-header with-border">
            <h3 class="box-title">
                <i class="fa fa-shield"></i> Proteksi Menu
            </h3>
        </div>
        <form action="{{ route('admin.settings.menu-protection') }}" method="POST">
            <div class="box-body">
                @csrf
                
                <div class="form-group">
                    <label for="menu_protection_enabled">Aktifkan Proteksi Anti-Intip</label>
                    <div>
                        <input type="checkbox" name="menu_protection_enabled" id="menu_protection_enabled" 
                               value="1" {{ $settings->menu_protection_enabled ? 'checked' : '' }} 
                               data-toggle="toggle">
                        <p class="text-muted small">
                            Jika diaktifkan, admin hanya dapat melihat server yang mereka buat sendiri.
                        </p>
                    </div>
                </div>

                <div class="form-group">
                    <label for="menu_protection_message">Pesan Proteksi</label>
                    <textarea name="menu_protection_message" id="menu_protection_message" 
                              class="form-control" rows="3" 
                              placeholder="Masukkan pesan yang akan ditampilkan ketika admin mencoba mengintip server lain">{{ old('menu_protection_message', $settings->menu_protection_message) }}</textarea>
                    <p class="text-muted small">
                        Pesan ini akan ditampilkan ketika admin mencoba mengakses server yang bukan miliknya.
                    </p>
                </div>
            </div>
            <div class="box-footer">
                <button type="submit" class="btn btn-primary btn-sm pull-right">
                    <i class="fa fa-save"></i> Save Settings
                </button>
            </div>
        </form>
    </div>
EOF

    # Insert the protection section before @endsection
    sed -i '/@endsection/ {
        r /tmp/protection_section.blade.php
    }' "$PANEL_PATH/resources/views/admin/settings.blade.php"
    
    # Clean up
    rm -f /tmp/protection_section.blade.php
    
    log_success "Settings view berhasil dimodifikasi"
}

# Run migrations and optimizations
run_optimizations() {
    log_info "Menjalankan migration dan optimizations..."
    
    cd "$PANEL_PATH"
    
    # Run migration
    php artisan migrate --force
    
    # Clear caches
    php artisan config:cache
    php artisan route:cache
    php artisan view:clear
    
    # Set permissions
    chown -R www-data:www-data "$PANEL_PATH"/
    chmod -R 755 "$PANEL_PATH"/
    chmod -R 755 "$PANEL_PATH"/storage
    
    log_success "Optimizations selesai"
}

# Restart services
restart_services() {
    log_info "Restarting services..."
    
    # Restart queue worker
    systemctl restart pteroq 2>/dev/null || log_warning "Tidak dapat restart pteroq"
    
    # Reload web server
    systemctl reload nginx 2>/dev/null || systemctl reload apache2 2>/dev/null
    
    log_success "Services berhasil di-restart"
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
    modify_settings_controller
    modify_settings_view
    run_optimizations
    restart_services
    
    log_success "🎉 Instalasi fitur Proteksi Menu berhasil diselesaikan!"
    log_info "📍 Lokasi backup: $BACKUP_DIR"
    log_info "🔧 Cara penggunaan:"
    log_info "   1. Login sebagai Admin ID 1"
    log_info "   2. Pergi ke Admin → Settings"
    log_info "   3. Scroll ke bagian 'Proteksi Menu'"
    log_info "   4. Aktifkan fitur dan atur pesan"
    log_info "   5. Save settings"
}

# Uninstall function
uninstall_protection() {
    log_warning "Fitur uninstall belum diimplementasikan"
    log_info "Anda dapat restore manual dari backup di: $BACKUP_DIR"
}

# Show usage
show_usage() {
    echo -e "${BLUE}Pterodactyl Menu Protection Installer${NC}"
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
