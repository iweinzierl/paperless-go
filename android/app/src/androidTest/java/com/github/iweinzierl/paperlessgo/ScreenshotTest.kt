package com.github.iweinzierl.paperlessgo

import android.content.Context
import android.graphics.Bitmap
import androidx.test.core.app.ActivityScenario
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.uiautomator.UiDevice
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileOutputStream
import org.junit.After
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import tools.fastlane.screengrab.Screengrab
import tools.fastlane.screengrab.ScreenshotCallback
import tools.fastlane.screengrab.UiAutomatorScreenshotStrategy
import tools.fastlane.screengrab.locale.LocaleTestRule

@RunWith(AndroidJUnit4::class)
class ScreenshotTest {
    private val instrumentation = InstrumentationRegistry.getInstrumentation()
    private val targetContext: Context = instrumentation.targetContext
    private val device: UiDevice = UiDevice.getInstance(instrumentation)
    private val screenshotStrategy = UiAutomatorScreenshotStrategy()

    @get:Rule
    val localeTestRule = LocaleTestRule()

    @Before
    fun setUp() {
        Screengrab.setDefaultScreenshotStrategy(screenshotStrategy)
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
            captureScreenshot("01-login-screen")
        }
    }

    @Test
    fun captureHomeScreen() {
        writeScenario(ScreenshotScenario.HOME, authenticated = true)

        launchMainActivity().use {
            waitForFlutterToSettle()
            captureScreenshot("02-home-screen")
        }
    }

    @Test
    fun captureDocumentsScreen() {
        writeScenario(ScreenshotScenario.DOCUMENTS, authenticated = true)

        launchMainActivity().use {
            waitForFlutterToSettle()
            captureScreenshot("03-document-list")
        }
    }

    @Test
    fun captureDocumentsDrawerScreen() {
        writeScenario(ScreenshotScenario.DOCUMENTS_DRAWER, authenticated = true)

        launchMainActivity().use {
            waitForFlutterToSettle()
            captureScreenshot("04-documents-drawer")
        }
    }

    @Test
    fun captureDocumentDetailScreen() {
        writeScenario(ScreenshotScenario.DOCUMENT_DETAIL, authenticated = true)

        launchMainActivity().use {
            waitForFlutterToSettle()
            captureScreenshot("05-document-detail")
        }
    }

    @Test
    fun captureSettingsScreen() {
        writeScenario(ScreenshotScenario.SETTINGS, authenticated = true)

        launchMainActivity().use {
            waitForFlutterToSettle()
            captureScreenshot("06-settings-screen")
        }
    }

    private fun captureScreenshot(name: String) {
        Screengrab.screenshot(
            name,
            screenshotStrategy,
            ExternalFileWritingScreenshotCallback(
                context = targetContext.applicationContext,
                locale = Screengrab.getLocale(),
            ),
        )
    }

    private fun launchMainActivity(): ActivityScenario<MainActivity> {
        device.pressHome()
        return ActivityScenario.launch(MainActivity::class.java)
    }

    private fun writeScenario(scenario: ScreenshotScenario, authenticated: Boolean) {
        val preferences = flutterPreferences()
        with(preferences.edit()) {
            putString("flutter.debug.screenshot_scenario", scenario.preferenceValue)
            putString("flutter.app_behavior.app_language", appLanguageForLocale())
            putString("flutter.sync.documents.last_success_at", "2026-03-21T09:30:00.000Z")

            if (authenticated) {
                putString("flutter.auth.server_url", "https://demo.paperless-ngx.local/")
                putString("flutter.auth.username", "demo.user")
                putString("flutter.auth.password", "not-used")
                putString("flutter.auth.token", "demo-token")
                putString("flutter.auth.display_name", "Demo User")
            }

            commit()
        }
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
        instrumentation.waitForIdleSync()
        device.waitForIdle()
        Thread.sleep(1500)
        instrumentation.waitForIdleSync()
    }

    private fun clearFlutterPreferences() {
        flutterPreferences().edit().clear().commit()
    }

    private fun flutterPreferences() =
        targetContext.getSharedPreferences("FlutterSharedPreferences", Context.MODE_PRIVATE)
}

private class ExternalFileWritingScreenshotCallback(
    private val context: Context,
    private val locale: String,
) : ScreenshotCallback {
    override fun screenshotCaptured(name: String, screenshot: Bitmap) {
        val baseDirectory =
            context.getExternalFilesDir("screengrab")
                ?: error("Unable to access external Screengrab directory")
        val screenshotDirectory =
            File(baseDirectory, "$locale/images/screenshots").apply { mkdirs() }
        val outputFile = File(
            screenshotDirectory,
            "${name}_${System.currentTimeMillis()}.png",
        )

        BufferedOutputStream(FileOutputStream(outputFile)).use { output ->
            screenshot.compress(Bitmap.CompressFormat.PNG, 100, output)
        }
        screenshot.recycle()
    }
}

private enum class ScreenshotScenario(val preferenceValue: String) {
    LOGIN("login"),
    HOME("home"),
    DOCUMENTS("documents"),
    DOCUMENTS_DRAWER("documents_drawer"),
    DOCUMENT_DETAIL("document_detail"),
    SETTINGS("settings"),
}