fn main() {
    tauri_build::mobile::PluginBuilder::new()
        .android_path("android")
        .ios_path("ios")
        .run();
}
