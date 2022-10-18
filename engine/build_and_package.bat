rm -rf zig-cache
rm -rf zig-out
zig build -fstage1 -Drelease-safe -Dtarget=x86_64-windows -Dvulkan_validation=false
python manage.py neurophobia