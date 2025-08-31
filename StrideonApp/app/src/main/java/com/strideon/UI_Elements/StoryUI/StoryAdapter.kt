package com.strideon.UI_Elements.StoryUI

import android.content.Context
import android.graphics.BitmapFactory
import android.os.Handler
import android.os.Looper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.ArrayAdapter
import android.widget.ImageView
import android.widget.TextView
import com.strideon.R
import java.net.URL
import java.util.concurrent.Executors

class StoryAdapter(private val context: Context, textViewResourceId: Int) :
    ArrayAdapter<StoryData>(context, textViewResourceId) {

    private val storylist: MutableList<StoryData?> = ArrayList()

    private lateinit var map_view: ImageView
    private lateinit var date: TextView
    private lateinit var distance: TextView
    private lateinit var points: TextView

    override fun add(`object`: StoryData?) {
        storylist.add(`object`)
        super.add(`object`)
    }

    override fun getCount(): Int {
        return storylist.size
    }

    override fun getItem(position: Int): StoryData? {
        return storylist[position]
    }

    override fun clear() {
        storylist.clear()
        super.clear()
        notifyDataSetChanged()
    }

    override fun remove(`object`: StoryData?) {
        storylist.remove(`object`)
        super.remove(`object`)
        notifyDataSetChanged()
    }

    // New function to update the adapter's data.
    fun setConvos(newConvos: List<StoryData>) {
        clear()
        storylist.addAll(newConvos)
        notifyDataSetChanged()
    }

    override fun getView(position: Int, convertView: View?, parent: ViewGroup): View {
        val record = getItem(position)
        var view = convertView
        val inflater = context.getSystemService(Context.LAYOUT_INFLATER_SERVICE) as LayoutInflater
        view = inflater.inflate(R.layout.item_record, parent, false)

        map_view = view.findViewById(R.id.map_view)
        date = view.findViewById(R.id.date)
        distance = view.findViewById(R.id.distance)
        points = view.findViewById(R.id.points)


        val executor = Executors.newSingleThreadExecutor()
        val handler = Handler(Looper.getMainLooper())
        executor.execute {
            try {
                val input = URL(record!!.map).openStream()
                val bitmap = BitmapFactory.decodeStream(input)
                handler.post {
                    map_view.setImageBitmap(bitmap)
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }

        date.text = record!!.date
        distance.text = record.distance
        points.text = record.points

        return view
    }

}