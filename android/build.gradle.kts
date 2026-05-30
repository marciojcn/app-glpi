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

// ── Workaround de namespace (AGP 8+) para plugins legados ──────────────────────
// Plugins antigos (ex.: blue_thermal_printer 1.2.3) não declaram `namespace`,
// obrigatório a partir do AGP 8. Injetamos o namespace a partir do atributo
// `package` do AndroidManifest do próprio plugin, no momento em que o plugin
// `com.android.library` é aplicado (antes da avaliação terminar). Reflection
// evita depender dos tipos do AGP no script raiz.
//
// IMPORTANTE: registrado ANTES do bloco `evaluationDependsOn(":app")`, senão o
// hook chegaria tarde demais (projeto já avaliado).
subprojects {
    plugins.withId("com.android.library") {
        val androidExtension = extensions.findByName("android") ?: return@withId
        val getNamespace = androidExtension.javaClass.methods
            .firstOrNull { it.name == "getNamespace" && it.parameterCount == 0 }
        val atual = getNamespace?.invoke(androidExtension) as String?
        if (atual.isNullOrEmpty()) {
            val manifest = file("src/main/AndroidManifest.xml")
            if (manifest.exists()) {
                val pkg = Regex("package=\"([^\"]+)\"")
                    .find(manifest.readText())?.groupValues?.get(1)
                if (!pkg.isNullOrEmpty()) {
                    androidExtension.javaClass.methods
                        .firstOrNull { it.name == "setNamespace" && it.parameterCount == 1 }
                        ?.invoke(androidExtension, pkg)
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
