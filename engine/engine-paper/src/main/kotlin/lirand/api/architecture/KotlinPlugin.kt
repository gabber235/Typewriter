package lirand.api.architecture

import com.github.shynixn.mccoroutine.folia.SuspendingJavaPlugin
import lirand.api.LirandAPI

abstract class KotlinPlugin : SuspendingJavaPlugin() {
	override fun onEnable() {
		try {
			LirandAPI.register(this)
		} catch (_: IllegalStateException) {}

		super.onEnable()
	}

}