# Upperkut changes

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

