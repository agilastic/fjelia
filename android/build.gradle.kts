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
subprojects {
    project.evaluationDependsOn(":app")
}
// Plugins compile against the app's API 37: newer AndroidX libraries refuse
// older ones (flutter_blue_plus is on 33), and the SDK ships 37 only as
// platforms;android-37.0, which compileSdk = 37 alone does not find.
subprojects {
    plugins.withId("com.android.library") {
        extensions.configure<com.android.build.api.variant.LibraryAndroidComponentsExtension> {
            finalizeDsl {
                it.compileSdk = 37
                it.compileSdkMinor = 0
                // Like the app: Kotlin 2.4 cannot inline JVM 11 bytecode into
                // plugins still on 1.8 (home_widget).
                it.compileOptions.sourceCompatibility = JavaVersion.VERSION_17
                it.compileOptions.targetCompatibility = JavaVersion.VERSION_17
                tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinJvmCompile>().configureEach {
                    compilerOptions.jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
                }
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
