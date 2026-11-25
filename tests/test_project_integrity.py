from pathlib import Path
import unittest

ROOT = Path(__file__).resolve().parents[1]


class ProjectIntegrityTests(unittest.TestCase):
    def read(self, path):
        return (ROOT / path).read_text(errors="replace")

    def test_project_is_marked_not_tested_yet(self):
        readme = self.read("README.md")
        self.assertIn("NOT TESTED YET ON A REAL ASUS CM1406", readme)
        self.assertIn("omarchy-cm1406-tarkin-0.3.0-dev.zip", readme)

    def test_top_level_installer_is_omarchy_default_and_permission_gated(self):
        text = self.read("install.sh")
        self.assertIn('TARKIN_WM="${TARKIN_WM:-omarchy}"', text)
        self.assertIn("J'AI L'AUTORISATION", text)
        self.assertIn("base/cm1406-arch/install/go.sh", text)

    def test_go_and_usb_installer_accept_omarchy(self):
        self.assertIn("omarchy|hyprland|niri", self.read("base/cm1406-arch/install/go.sh"))
        self.assertIn("omarchy|hyprland|niri|none", self.read("base/cm1406-arch/install/install-usb.sh"))

    def test_chromeos_boot_flags_are_read_only(self):
        lib = self.read("base/cm1406-arch/scripts/lib-chromeos.sh")
        installer = self.read("base/cm1406-arch/install/install-usb.sh")
        repair = self.read("base/cm1406-arch/scripts/repair-boot.sh")
        self.assertIn("tarkin_require_usb_boot_preconfigured", lib)
        self.assertNotIn("tarkin_enable_usb_boot", lib + installer + repair)
        self.assertNotIn('crossystem "$n=1"', lib)
        self.assertNotIn('crossystem dev_boot_signed_only=0', lib)

    def test_omarchy_package_installer_uses_signed_aarch64_edge(self):
        text = self.read("omarchy/rootfs-overlay/usr/local/libexec/tarkin/omarchy-install-packages")
        self.assertIn("40DFB630FF42BCFFB047046CF0134EE680CAC571", text)
        self.assertIn("https://pkgs.omarchy.org/edge/$arch", text)
        self.assertIn("SigLevel = Required DatabaseOptional", text)
        self.assertIn("omarchy-dev", text)
        self.assertIn("pacman -Si chromium", text)
        self.assertIn("pacman -Si firefox", text)
        self.assertIn("unavailable", text)
        self.assertIn("--ignore", text)

    def test_tarkin_firstboot_runs_gpu_only_then_user_finalizer(self):
        text = self.read("base/cm1406-arch/rootfs/usr/local/libexec/tarkin/firstboot")
        self.assertIn("--gpu-only", text)
        self.assertIn("omarchy-firstboot", text)
        self.assertIn('FIRSTBOOT_WM" == omarchy', text)

    def test_overlay_dropin_reuses_existing_tarkin_console(self):
        dropin = self.read("omarchy/rootfs-overlay/etc/systemd/system/tarkin-console.service.d/50-omarchy-session.conf")
        self.assertIn("ExecStart=/usr/local/libexec/tarkin/omarchy-session", dropin)
        self.assertIn("PAMName=login", dropin)
        self.assertFalse((ROOT / "omarchy/rootfs-overlay/etc/systemd/system/tarkin-console.service.d/50-omarchy-session.conf.example").exists())

    def test_adapter_requires_successful_firstboot_marker(self):
        text = self.read("omarchy/rootfs-overlay/usr/local/libexec/tarkin/omarchy-session")
        self.assertIn("/var/lib/tarkin/omarchy-ready", text)
        self.assertIn("TARKIN_OMARCHY_SESSION", text)
        self.assertIn("/usr/local/bin/hyprland-mali", text)
        self.assertIn("uwsm start -e -D Hyprland -- /usr/local/bin/hyprland-mali", text)
        self.assertNotIn("uwsm start -g -1", text)

    def test_no_second_display_manager_unit(self):
        unit_dir = ROOT / "omarchy/rootfs-overlay/etc/systemd/system"
        self.assertEqual(list(unit_dir.rglob("*.service")), [])

    def test_no_quigon_hardware_in_tarkin_config(self):
        profile = self.read("omarchy/device/tarkin.conf")
        self.assertIn('DEVICE_TREE_COMPATIBLE="google,tarkin"', profile)
        self.assertNotIn("google,obiwan", profile)
        self.assertNotIn("mt8189_1019_rt5682s", profile)

    def test_verify_script_is_non_destructive(self):
        text = self.read("scripts/verify-project.sh")
        self.assertIn("bash -n", text)
        self.assertNotIn("pacman -S", text)
        self.assertNotIn("dd if=", text)


if __name__ == "__main__":
    unittest.main()
