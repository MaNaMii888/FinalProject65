allprojects {
    repositories {
        google()
        mavenCentral()
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

// Ensure all subprojects (including plugins) compile with Java 11 and Kotlin jvmTarget=11
subprojects {
    // Java compile settings
    tasks.withType<JavaCompile>().configureEach {
        // Set source/target compatibility to Java 11 for subprojects.
        sourceCompatibility = JavaVersion.VERSION_11.toString()
        targetCompatibility = JavaVersion.VERSION_11.toString()
    }

    // Kotlin compile settings (if Kotlin is applied in the subproject)
    // Ensure all Kotlin compilation targets JVM 11 to match Java settings.
    try {
        @Suppress("UNCHECKED_CAST")
        tasks.withType(org.jetbrains.kotlin.gradle.tasks.KotlinCompile::class.java).configureEach {
            kotlinOptions {
                jvmTarget = JavaVersion.VERSION_11.toString()
            }
        }
    } catch (e: Exception) {
        // If Kotlin plugin is not applied in some plugin/subproject this will be ignored.
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
