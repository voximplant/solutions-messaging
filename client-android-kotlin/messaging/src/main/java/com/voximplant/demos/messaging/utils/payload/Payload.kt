package com.voximplant.demos.messaging.utils.payload

typealias Payload = MutableList<MutableMap<String,Any>>

private const val latitude = "latitude"
private const val longitude = "longitude"

var Payload.locationLatitude: Double?
    get() = this.first()[latitude] as? Double
    set(value) {
        if (value != null) {
            if (this.size <= 0) {
                val map: MutableMap<String, Any> = mutableMapOf()
                map[latitude] = value
                this.add(map)
            } else {
                this.first()[latitude] = value
            }
        }
    }

var Payload.locationLongitude: Double?
    get() = this.first()[longitude] as? Double
    set(value) {
        if (value != null) {
            if (this.size <= 0) {
                val map: MutableMap<String, Any> = mutableMapOf()
                map[longitude] = value
                this.add(map)
            } else {
                this.first()[longitude] = value
            }
        }
    }