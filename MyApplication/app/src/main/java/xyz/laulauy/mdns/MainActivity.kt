package xyz.laulauy.mdns

import android.content.Context
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.os.Bundle
import android.util.Log
import com.google.android.material.floatingactionbutton.FloatingActionButton
import com.google.android.material.snackbar.Snackbar
import androidx.appcompat.app.AppCompatActivity
import android.view.Menu
import android.view.MenuItem
import java.net.InetAddress

class MainActivity : AppCompatActivity() {

    private var nsdManager: NsdManager? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        setSupportActionBar(findViewById(R.id.toolbar))

        findViewById<FloatingActionButton>(R.id.fab).setOnClickListener { view ->
            Snackbar.make(view, "Replace with your own action", Snackbar.LENGTH_LONG)
                    .setAction("Action", null).show()

            registerService(7666)
        }


    }

    private val registrationListener = object : NsdManager.RegistrationListener {
        override fun onServiceRegistered(serviceInfo: NsdServiceInfo?) {
            // Save the service name. Android may have changed it in order to
            // resolve a conflict, so update the name you initially requested
            // with the name Android actually used.
            val mServiceName = serviceInfo?.serviceName
            Log.d("nsd", "onServiceRegistered")
        }

        override fun onRegistrationFailed(serviceInfo: NsdServiceInfo?, errorCode: Int) {
            TODO("Not yet implemented")
            //Registration failed! Put debugging code here to determine why.
            Log.d("nsd", "onRegistrationFailed")
        }

        override fun onServiceUnregistered(serviceInfo: NsdServiceInfo?) {
            TODO("Not yet implemented")
            // Service has been unregistered. This only happens when you call
            // NsdManager.unregisterService() and pass in this listener.
            Log.d("nsd", "onServiceUnregistered")
        }

        override fun onUnregistrationFailed(serviceInfo: NsdServiceInfo?, errorCode: Int) {
            TODO("Not yet implemented")
            // Unregistration failed. Put debugging code here to determine why.
            Log.d("nsd", "onUnregistrationFailed")
        }
    }
    private val discoveryListener = object : NsdManager.DiscoveryListener {
        override fun onDiscoveryStarted(serviceType: String?) {
        }

        override fun onServiceFound(serviceInfo: NsdServiceInfo?) {
            val resolverListener = object : NsdManager.ResolveListener {
                override fun onServiceResolved(serviceInfo: NsdServiceInfo?) {
                    Log.e("TAG", "Resolve Succeeded. $serviceInfo.")
//            if (serviceInfo?.serviceName == "eeweb") {
//                Log.d("TAG", "Same IP.")
//                return
//            }
//            mService = serviceInfo
                    val port: Int? = serviceInfo?.port
                    val host: InetAddress? = serviceInfo?.host
                    val chn = host?.canonicalHostName
                    val hostname = host?.hostName
                    val bb = host?.hostAddress
                    Log.e("TAG", "InetAddress Succeeded. $host -  $chn - $hostname - $bb")
                }
                override fun onResolveFailed(serviceInfo: NsdServiceInfo?, errorCode: Int) {
                    Log.e("TAG", "Resolve Failed. $serviceInfo")
                }
            }
            nsdManager?.resolveService(serviceInfo, resolverListener)
//            when {
//                serviceInfo?.serviceType != "_http._tcp" ->
//                    Log.d("tag", "Unknown Service Type: ${serviceInfo?.serviceType}")
//                serviceInfo?.serviceName == "eeweb" ->
//                    Log.d("tag", "Unknown Service Type: ${serviceInfo?.serviceType}")
//                serviceInfo?.serviceName.contains("NsdChat") ->
//                    nsdManager?.resolveService(serviceInfo, resolverListener)
//            }
        }

        override fun onServiceLost(serviceInfo: NsdServiceInfo?) {
        }

        override fun onDiscoveryStopped(serviceType: String?) {
        }

        override fun onStartDiscoveryFailed(serviceType: String?, errorCode: Int) {
            nsdManager?.stopServiceDiscovery(this)
        }

        override fun onStopDiscoveryFailed(serviceType: String?, errorCode: Int) {
            nsdManager?.stopServiceDiscovery(this)
        }
    }
    fun registerService(port: Int) {
        val serviceInfo = NsdServiceInfo().apply {
            serviceName = "CustomName"
            serviceType = "_custom._tcp."
            setPort(port)
        }
        if (nsdManager == null) {
            nsdManager = (getSystemService(Context.NSD_SERVICE) as NsdManager)
            nsdManager?.registerService(serviceInfo, NsdManager.PROTOCOL_DNS_SD, registrationListener)
            nsdManager?.discoverServices("_custom._tcp.", NsdManager.PROTOCOL_DNS_SD, discoveryListener)
        }
    }


    override fun onCreateOptionsMenu(menu: Menu): Boolean {
        // Inflate the menu; this adds items to the action bar if it is present.
        menuInflater.inflate(R.menu.menu_main, menu)
        return true
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        // Handle action bar item clicks here. The action bar will
        // automatically handle clicks on the Home/Up button, so long
        // as you specify a parent activity in AndroidManifest.xml.
        return when (item.itemId) {
            R.id.action_settings -> true
            else -> super.onOptionsItemSelected(item)
        }
    }
}