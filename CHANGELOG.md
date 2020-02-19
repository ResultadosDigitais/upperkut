# Upperkut changes

0.7.x
---------
- Fix logging timeout message #54 by @jeanmatheussouto
- Add handle_error method #44
- Added Datahog Middleware (#42)
- Added Priority Queue (#39) thanks to @jeangnc and @jeanmatheussouto
- Added Scheduled Queue Implementation thanks to @rodrigo-araujo #38
- Added Datahog middleware #42 by @gabriel-augusto
- Added redis to CI #40 by #henrich-m
- Specs improvements #34 and #35, #37 by @gabriel-augusto
- Enable Rubocop #32 by @henrich-m
- Added codeclimate #31 by @henrich-m
- Extract Buffered Queue behavior to its own strategy #29

0.6.x
---------
- Set redis url when env var REDIS_URL is set thanks to @lucaskds #22
- Enable users to pass their own connection pool also thanks to @lucaskds #21
- Sets default concurrency to 1
- Creates connection pools by default;
- Simplifies API to enable extension via Strategy;

0.5.x
----------
- Introducing client middlewares.
- Fix issue that prevented worker to run.
- Fix thread-unsafe code that was overwriting worker configurations when
multiples workers were configured in the same process.

0.4.x
-----------

- Change redis versioning policy #17
- Fixed error that prevented users from start upperkut from non Rails apps.
- Added integration with Rollbar.
- Added backtrace to logs when some error occurs.
- Fixed NewRelic trace args

