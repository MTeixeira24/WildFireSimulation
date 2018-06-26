// GENERATES USERS FOR TESTING PURPOSES
const fs = require('fs');
const http = require('http');

if(process.argv.length === 3 || process.argv.length === 4) {
	let queryString = '';
	if (process.argv.length === 3) { // id of the city from openWheatherMap
		queryString = 'id=' + process.argv[2];
	} else if (process.argv.length === 4){ // name of the city and country
		queryString = 'q=' + process.argv[2] + ',' + process.argv[3];
	}

	http.get('http://api.openweathermap.org/data/2.5/forecast?' + queryString + '&mode=json&appid=af4e6ee41fd448411a225c66a67015e5', (resp) => {
		let data = '';

		// A chunk of data has been recieved.
		resp.on('data', (chunk) => {
			data += chunk;
		});

		// The whole response has been received. Print out the result.
		resp.on('end', () => {
			data = JSON.parse(data);
			var list = data.list;
			console.log(data);

			var temperatures = [];
			var precipitations = [];
			var humidity = [];
			var wind = [];

			list.forEach(function(item){
				for (var i = 0; i < 3; i++) { // information is not hourly, it is from 3 to 3 hours
					temperatures.push(item.main.temp - 273.15); // Kelvin -> Celsius
					if (item.rain) {
						precipitations.push(item.rain['3h'] ? item.rain['3h'] : 0); // Precipitation in mm [0 - 100]
					}
					humidity.push(item.main.humidity); // Humidity in percentage [0 - 100]
					wind.push([item.wind.speed, item.wind.deg > 180 ? item.wind.deg - 360 : item.wind.deg]); // Wind degrees from [0, 360] to [-180, 180]
				}
			});

			console.log(temperatures);
			console.log(precipitations);
			console.log(humidity);
			console.log(wind);

			var wstream = fs.createWriteStream('configs/' + data.city.name + '_' + data.city.country + '_' + data.list[0].dt_txt.replace(/:/g,'_'));
			
			wstream.write(JSON.stringify(temperatures).replace(/,/g,' '));
			wstream.write('\n');
			wstream.write(JSON.stringify(precipitations).replace(/,/g,' '));
			wstream.write('\n');
			wstream.write(JSON.stringify(humidity).replace(/,/g,' '));
			wstream.write('\n');
			wstream.write(JSON.stringify(wind).replace(/,/g,' '));
			wstream.end();

		});

	}).on("error", (err) => {
		console.log("Error: " + err.message);
	});

} else {
	console.log('Usage:\n' +
		'Specify the id of the city from OpenWeatherMap, i. e.:\n' +
		'> node openweathermap.js 2735943\n' +
		'\n' +
		'or\n' +
		'\n' +
		'Specify the name of the city and the country, i. e.:\n' +
		'> node openweathermap.js porto pt');
}