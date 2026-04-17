package com.kyvronix.phoneguard.alarm

import android.content.Context
import android.media.AudioManager
import android.media.MediaPlayer
import android.media.RingtoneManager
import android.net.Uri
import android.util.Log

class AlarmController(private val context: Context) {
    companion object {
        private var mediaPlayer: MediaPlayer? = null
        private var previousVolume: Int = 0
    }

    fun startAlarm() {
        try {
            if (mediaPlayer?.isPlaying == true) return
            
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            previousVolume = audioManager.getStreamVolume(AudioManager.STREAM_ALARM)
            val maxVolume = audioManager.getStreamMaxVolume(AudioManager.STREAM_ALARM)
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, maxVolume, 0)

            val ringtoneUri: Uri? = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_ALARM)
                ?: RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE)
            
            if (ringtoneUri == null) {
                Log.e("AlarmController", "Could not find any alarm or ringtone URI")
                return
            }

            mediaPlayer = MediaPlayer().apply {
                setDataSource(context, ringtoneUri)
                setAudioStreamType(AudioManager.STREAM_ALARM)
                isLooping = true
                prepare()
                start()
            }
        } catch (e: Exception) {
            Log.e("AlarmController", "Failed to start alarm", e)
        }
    }

    fun stopAlarm() {
        try {
            mediaPlayer?.let {
                if (it.isPlaying) {
                    it.stop()
                }
                it.release()
            }
            mediaPlayer = null
            
            val audioManager = context.getSystemService(Context.AUDIO_SERVICE) as AudioManager
            audioManager.setStreamVolume(AudioManager.STREAM_ALARM, previousVolume, 0)
        } catch (e: Exception) {
            Log.e("AlarmController", "Failed to stop alarm", e)
        }
    }
}
