// Root build.gradle.kts — Flutter Android-standard.
//
// VIKTIG (Sprint 8 ryddejobb): denne filen skal IKKE inneholde:
//   - pluginManagement { ... }                  (hører i settings.gradle.kts)
//   - plugins { ... } med versjoner             (hører i settings.gradle.kts)
//   - dependencyResolutionManagement { ... }    (hører i settings.gradle.kts)
//   - rootProject.name                          (hører i settings.gradle.kts)
//   - include(":app")                           (hører i settings.gradle.kts)
//
// Hvis du legger plugin-versjoner her vil de kollidere med versjonene
// i settings.gradle.kts og gi feil av typen:
//   "plugin is already on classpath with different version"

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Flutter-konvensjon: legg build/-mappen ett nivå opp så Android Studio
// og Flutter CLI deler samme build-output. Gjør 'flutter clean' og
// Android Studio-build kompatible.
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