package com.kyvronix.phoneguard.services

import android.content.Context
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import com.kyvronix.phoneguard.utils.StateSyncManager
import kotlinx.coroutines.CompletableDeferred

/**
 * Worker responsible for synchronizing device state to Firestore.
 * Used as a replacement for dataSync foreground services that are restricted on Android 14+.
 */
class SyncWorker(context: Context, params: WorkerParameters) : CoroutineWorker(context, params) {
    override suspend fun doWork(): Result {
        val event = inputData.getString("event") ?: "WORKER_SYNC"
        
        // StateSyncManager.syncState is asynchronous, we wait for it to complete
        val deferred = CompletableDeferred<Unit>()
        StateSyncManager.syncState(applicationContext, event) {
            deferred.complete(Unit)
        }
        
        return try {
            deferred.await()
            Result.success()
        } catch (e: Exception) {
            Result.retry()
        }
    }
}
