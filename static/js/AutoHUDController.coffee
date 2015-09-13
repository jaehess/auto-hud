window.AutoHUDController = {
	setWatchers: ->
		@watchTime()
		@watchWeather()
		@watchSubwayStatus()


	# time and date
	#############################################################################

	watchTime: ->
		@timeWatcher = setInterval(=>
			@setTime()
		, 1000)

	setTime: ->
		d = new Date()

		minutes = d.getMinutes()
		if minutes < 10
			minutes = "0#{minutes}"

		seconds = d.getSeconds()
		if seconds < 10
			seconds = "0#{seconds}"

		month = @C.months[d.getMonth()]

		@model.set({
			time: "#{d.getHours()}:#{minutes}:#{seconds}"
			date: "#{month} #{d.getDate()}, #{d.getFullYear()}"
		})


	# weather
	#############################################################################

	watchWeather: ->
		@getWeather()
		setInterval(=>
			@getWeather()
		, @C.weatherPollTime)

	getWeather: ->
		url = "#{@C.weatherUrl}#{@model.get("forecastioApiKey")}/#{@model.get("forecastioLatLong")}"

		# to use test data, comment out the `getJSON` and add:
		# @formatWeather(weatherData)
		$.getJSON("#{url}?callback=?", (data) =>
			@formatWeather(data)
		)

	###
	Format weather data from forecast.io into something a little more simple:
	current: 75º, rain
	today: 65º-77º, rain in the afternoon
	###
	formatWeather: (data) ->
		weather = {
			current: {}
			today: {}
		}

		weather.current.temperature = @formatTemperature(data.currently.apparentTemperature)
		weather.current.summary = data.currently.summary
		weather.current.icon = data.currently.icon

		today = data.daily.data[0]

		weather.today.low = @formatTemperature(today.temperatureMin)
		weather.today.high = @formatTemperature(today.temperatureMax)
		weather.today.summary = today.summary.replace(/\.$/, "")
		weather.today.icon = today.icon

		@model.set({weather: weather})

	formatTemperature: (temperature) ->
		temperature = Math.round(temperature)

		return "#{temperature}ºF"


	# subway
	#############################################################################

	watchSubwayStatus: ->
		@getSubwayStatus()
		setInterval(=>
			@getSubwayStatus()
		, @C.subwayPollTime)

	getSubwayStatus: ->
		$.ajax(@C.subwayUrl, {
			type: "GET"
			dataType: "xml"
			success: (data) =>
				@parseSubwayStatus(data)
		})

	parseSubwayStatus: (data) ->
		subwayStatus = {}

		return if !data || !$(data).length

		for line in $(data).find("service subway line")
			line = $(line)
			name = line.find("name")
			status = line.find("status")

			# bail if there's a missing element
			continue if !name.length || !status.length

			name = name.text()
			status = status.text()

			# bail if we don't care about this subway line
			continue if !@C.subwayLinesToShow[name]

			subwayStatus[name] = status

		@model.set({subwayStatus: subwayStatus})
}