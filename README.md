# Airweb.Umbrella

**NOTE: NO GUARANTEES OF FITNESS, CORRECTNESS BLABLABLABLA**

AirWeb takes an activity log and computes and presents a daily, per project and
project-per-day breakdown of the activities. An example:

```
Må 08:00 AS
Ti 08:45-12:45 AS
13:30-18:45
00:30 Talang - HW-slides
On 08:45-12:15 AS
13:00-19:15
To 08:45-12:30 AS
13:15-16:30
16:30-18:00 IA - ftg-möte
Fr 08:30-12:45 AS
13:45-17:30
```

... becomes ...

```
Daily hours: [{"Må", 8.0}, {"Ti", 9.75}, {"On", 9.75}, {"To", 8.5}, {"Fr", 8.0}]
Week total: 44.0 (-4.0 remaining)
Tag sum:
 {"AS", 42.0}
 {"IA - ftg-möte", 1.5}
 {"Talang - HW-slides", 0.5}
Daily tag sums:
 %{"AS" => 8.0}
 %{"AS" => 9.25, "Talang - HW-slides" => 0.5}
 %{"AS" => 9.75}
 %{"AS" => 7.0, "IA - ftg-möte" => 1.5}
 %{"AS" => 8.0}
```

Enjoy!

## Running

Starting the app is as easy as `(cd where/code/lives/airweb_umbrella; mix phx.server)`, if you've done the usual deps
fetching and building, see `mix help deps` for more information.

## Building

Building is rather easy:

```
# only the first time
mix deps.get
mix
```

## TODO

See the issues on GitHub for The Truth™. The next big-picture items are:

- [ ] moar(?) tests
- [ ] change internal representation of time from floats to 1/60ths
- [ ] deploy IRL, not just locally
- [ ] create a companion browser-extension that uses IRL-deployment
