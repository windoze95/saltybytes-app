allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Some pub plugins (vosk_flutter_2 1.0.5) predate AGP 8's mandatory `namespace`
// and only carry a `package` attribute in their manifest, which AGP 8 refuses
// to configure. Backfill the namespace from that attribute so they still build.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
            if (namespace == null) {
                val manifest = file("src/main/AndroidManifest.xml")
                if (manifest.exists()) {
                    Regex("package=\"([^\"]+)\"")
                        .find(manifest.readText())
                        ?.groupValues
                        ?.get(1)
                        ?.let { namespace = it }
                }
            }
        }
    }
}

subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
