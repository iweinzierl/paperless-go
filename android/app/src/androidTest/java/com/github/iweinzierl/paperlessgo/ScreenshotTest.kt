package com.github.iweinzierl.paperlessgo

import android.content.Context
import android.os.Environment
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.By
import androidx.test.uiautomator.UiDevice
import java.io.File
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import tools.fastlane.screengrab.Screengrab
import tools.fastlane.screengrab.locale.LocaleTestRule

@RunWith(AndroidJUnit4::class)
class ScreenshotTest {
    private companion object {
        private const val screenshotStatePreferenceKey = "flutter.debug.screenshot_state"
    }

    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val launchArguments = InstrumentationRegistry.getArguments()
    private val targetContext: Context = instrumentation.targetContext
    private val device: UiDevice = UiDevice.getInstance(instrumentation)

    @get:Rule
    val localeTestRule = LocaleTestRule()

    @Before
    fun setUp() {
        clearFlutterPreferences()
    }

    @After
    fun tearDown() {
        clearFlutterPreferences()
    }

    @Test
    fun captureLoginScreen() {
        writeScenario(ScreenshotScenario.LOGIN, authenticated = false)

        launchMainActivity().use {
            waitForFlutterToSettle()
            captureScreenshot("01-login-screen", it)
        }
    }

    @Test
    fun captureDocumentsScreen() {
        writeScenario(ScreenshotScenario.DOCUMENTS, authenticated = true)

        launchMainActivity().use {
            waitForFlutterToSettle()
            captureScreenshot("02-document-list", it)
        }
    }

    @Test
    fun captureCondensedDocumentsScreen() {
        writeScenario(ScreenshotScenario.DOCUMENTS_LIST, authenticated = true)

        launchMainActivity().use {
            waitForFlutterToSettle()
            captureScreenshot("03-document-list-condensed", it)
        }
    }

    @Test
    fun captureDocumentsFiltersScreen() {
        writeScenario(ScreenshotScenario.DOCUMENTS_FILTERS, authenticated = true)

        launchMainActivity().use {
            waitForFlutterToSettle()
            captureScreenshot("04-filter-sort", it)
        }
    }

    @Test
    fun captureDocumentsDrawerScreen() {
        writeScenario(ScreenshotScenario.DOCUMENTS_DRAWER, authenticated = true)

        launchMainActivity().use {
            waitForFlutterToSettle()
            captureScreenshot("07-documents-drawer", it)
        }
    }

    @Test
    fun captureDocumentDetailScreen() {
        writeScenario(ScreenshotScenario.DOCUMENT_DETAIL, authenticated = true)

        launchMainActivity().use {
            waitForFlutterToSettle()
            captureScreenshot("05-document-detail", it)
        }
    }

    @Test
    fun captureDocumentMetadataEditScreen() {
        writeScenario(ScreenshotScenario.DOCUMENT_METADATA_EDIT, authenticated = true)

        launchMainActivity().use {
            waitForFlutterToSettle()
            captureScreenshot("06-document-metadata-edit", it)
        }
    }

    @Test
    fun captureSettingsScreen() {
        writeScenario(ScreenshotScenario.SETTINGS, authenticated = true)

        launchMainActivity().use {
            waitForFlutterToSettle()
            captureScreenshot("08-settings-screen", it)
        }
    }

    private fun captureScreenshot(name: String, scenario: ActivityScenario<MainActivity>) {
        scenario.onActivity {
            device.waitForIdle()
            Thread.sleep(500)

            val outputFile = createScreenshotOutputFile(name)
            if (outputFile.exists()) {
                check(outputFile.delete()) {
                    "Failed to replace screenshot: ${outputFile.absolutePath}"
                }
            }
            check(device.takeScreenshot(outputFile)) {
                "Failed to capture screenshot: ${outputFile.absolutePath}"
            }
        }
    }

    private fun launchMainActivity(): ActivityScenario<MainActivity> {
        device.pressHome()
        return ActivityScenario.launch(MainActivity::class.java)
    }

    private fun writeScenario(scenario: ScreenshotScenario, authenticated: Boolean) {
        val preferences = flutterPreferences()
        val dataSource = screenshotDataSource(authenticated)
        with(preferences.edit()) {
            putString("flutter.debug.screenshot_scenario", scenario.preferenceValue)
            putString("flutter.debug.screenshot_data_source", dataSource)
            putString(screenshotStatePreferenceKey, "loading")
            putString("flutter.app_behavior.app_language", appLanguageForLocale())
            putString("flutter.sync.documents.last_success_at", "2026-03-21T09:30:00.000Z")
            putString(
                "flutter.documents.layout_mode",
                when (scenario) {
                    ScreenshotScenario.DOCUMENTS_LIST -> "list"
                    else -> "card"
                },
            )

            if (authenticated) {
                when (dataSource) {
                    "live" -> {
                        putString(
                            "flutter.auth.server_url",
                            requiredLaunchArgument("paperlessScreenshotServerUrl"),
                        )
                        putString(
                            "flutter.auth.username",
                            requiredLaunchArgument("paperlessScreenshotUsername"),
                        )
                        putString(
                            "flutter.auth.password",
                            requiredLaunchArgument("paperlessScreenshotPassword"),
                        )
                        remove("flutter.auth.token")

                        optionalLaunchArgument("paperlessScreenshotDisplayName")
                            ?.let { putString("flutter.auth.display_name", it) }
                            ?: remove("flutter.auth.display_name")
                    }

                    else -> {
                        putString("flutter.auth.server_url", "https://demo.paperless-ngx.local/")
                        putString("flutter.auth.username", "demo.user")
                        putString("flutter.auth.password", "not-used")
                        putString("flutter.auth.token", "demo-token")
                        putString("flutter.auth.display_name", "Demo User")
                    }
                }
            }

            commit()
        }
    }

    private fun screenshotDataSource(authenticated: Boolean): String {
        val configuredValue = optionalLaunchArgument("paperlessScreenshotDataSource")?.lowercase()
        if (!configuredValue.isNullOrEmpty()) {
            return configuredValue
        }

        return if (authenticated) "live" else "mock"
    }

    private fun requiredLaunchArgument(name: String): String {
        return optionalLaunchArgument(name)
            ?: error("Missing required screenshot launch argument '$name'.")
    }

    private fun optionalLaunchArgument(name: String): String? {
        val value = launchArguments.getString(name)?.trim()
        return value?.takeIf { it.isNotEmpty() }
    }

    private fun appLanguageForLocale(): String {
        return when (Screengrab.getLocale().substringBefore('-').lowercase()) {
            "de" -> "de"
            "es" -> "es"
            "fr" -> "fr"
            "it" -> "it"
            else -> "en"
        }
    }

    private fun waitForFlutterToSettle() {
        waitForScreenshotReady()
        instrumentation.waitForIdleSync()
        device.waitForIdle()
        Thread.sleep(500)
        instrumentation.waitForIdleSync()
    }

    private fun waitForScreenshotReady(timeoutMillis: Long = 30_000L) {
        val deadline = System.currentTimeMillis() + timeoutMillis
        while (System.currentTimeMillis() < deadline) {
            instrumentation.waitForIdleSync()
            device.waitForIdle()
            val screenshotState = flutterPreferences().getString(screenshotStatePreferenceKey, null)

            if (screenshotState == "error") {
                error("Screenshot harness entered an error state.")
            }

            if (screenshotState == "ready") {
                return
            }

            Thread.sleep(250)
        }

        val finalState = flutterPreferences().getString(screenshotStatePreferenceKey, null)
        error("Timed out waiting for screenshot harness ready state. Last state=$finalState")
    }

    private fun clearFlutterPreferences() {
        flutterPreferences().edit().clear().commit()
    }

    private fun flutterPreferences() =
        targetContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)

    private fun createScreenshotOutputFile(name: String): File {
        val sharedBaseDirectory =
            File(Environment.getExternalStorageDirectory(), "${targetContext.packageName}/screengrab")
        val baseDirectory =
            if (sharedBaseDirectory.exists() || sharedBaseDirectory.mkdirs()) {
                sharedBaseDirectory
            } else {
                targetContext.applicationContext.getExternalFilesDir("screengrab")
                    ?: error("Unable to access external Screengrab directory")
            }
        val screenshotDirectory =
            File(baseDirectory, "${Screengrab.getLocale()}/images/screenshots").apply { mkdirs() }

        return File(
            screenshotDirectory,
            "$name.png",
        )
    }
}

private enum class ScreenshotScenario(val preferenceValue: String) {
    LOGIN("login"),
    DOCUMENTS("documents"),
    DOCUMENTS_LIST("documents_list"),
    DOCUMENTS_FILTERS("documents_filters"),
    DOCUMENTS_DRAWER("documents_drawer"),
    DOCUMENT_DETAIL("document_detail"),
    DOCUMENT_METADATA_EDIT("document_metadata_edit"),
    SETTINGS("settings"),
}