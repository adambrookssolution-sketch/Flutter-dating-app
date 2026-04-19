allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Force every Android subproject (including Flutter plugins like `jni`) to
// use the NDK version we actually have installed locally. Without this,
// plugins that bump their required NDK (e.g. jni 1.0.0 wants 28.2.13676358)
// trigger a download that silently fails on machines without cmdline-tools,
// leaving an empty NDK folder and a build-time InstallFailedException.
val affinityNdkVersion = "28.2.13676358"

subprojects {
    plugins.withId("com.android.application") {
        extensions.configure<com.android.build.gradle.AppExtension>("android") {
            ndkVersion = affinityNdkVersion
        }
    }
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.gradle.LibraryExtension>("android") {
            ndkVersion = affinityNdkVersion
        }
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
