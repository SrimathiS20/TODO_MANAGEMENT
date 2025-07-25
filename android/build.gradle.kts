// Top-level build.gradle.kts

import org.gradle.api.tasks.Delete
import org.gradle.api.file.Directory

buildscript {
    dependencies {
        // ✅ Firebase Google Services Plugin
        classpath("com.google.gms:google-services:4.4.1")
    }
    repositories {
        google()
        mavenCentral()
    }
}

// ✅ Optional: Custom build directory setup
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

subprojects {
    project.evaluationDependsOn(":app")
}

// ✅ Clean task
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
