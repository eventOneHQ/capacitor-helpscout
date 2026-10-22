package io.event1.plugins.helpscout

import com.helpscout.beacon.model.BeaconScreens
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class HelpScoutScreenTest {
    @Test
    fun mapsJavaScriptNamesToBeaconScreens() {
        assertEquals(BeaconScreens.DEFAULT, HelpScoutScreen.fromJsName("home")?.beaconScreen)
        assertEquals(BeaconScreens.CONTACT_FORM_SCREEN, HelpScoutScreen.fromJsName("askMessage")?.beaconScreen)
        assertEquals(BeaconScreens.CHAT, HelpScoutScreen.fromJsName("askChat")?.beaconScreen)
        assertEquals(BeaconScreens.AI_ANSWERS, HelpScoutScreen.fromJsName("aiAnswers")?.beaconScreen)
        assertEquals(BeaconScreens.PREVIOUS_MESSAGES, HelpScoutScreen.fromJsName("previousMessages")?.beaconScreen)
    }

    @Test
    fun rejectsUnknownScreens() {
        assertNull(HelpScoutScreen.fromJsName("nope"))
    }
}
