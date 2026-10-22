package io.event1.plugins.helpscout

import com.getcapacitor.Logger

class HelpScout {

    fun echo(value: String): String {
        Logger.info("Echo", value)

        return value
    }
}
