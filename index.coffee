async = require "async"
_ = require "underscore"
moment = require "moment"

Api = require "./api"
config = require "./config.json"

api = new Api config

OFFSET = 0

toDay = moment().set({
  hour:0
  minute: 0
  second: 0
  millisecond: 0
})
.subtract OFFSET, "day"

periodStart = moment config.startPeriod

currentPeriodEnd = periodStart.clone().subtract(1, "day")

while currentPeriodEnd.isBefore(toDay)
  currentPeriodEnd.add config.period
days = []

currentPeriodStart = currentPeriodEnd.clone().subtract(config.period).add(1, "day")
currentPeriodEnd.add(1, "day").subtract(1, "millisecond")

day = currentPeriodStart.clone()

while day.isBefore(currentPeriodEnd)
  days.push {
    dayOfWeek: day.format("ddd")
    free: day.format("ddd") in config.freeDays
    left: day.isAfter toDay
  }
  day.add 1, "day"

workDaysLeft = _.filter(days, (d)-> d.free isnt true and d.left).length

async.parallel(
  {
    todayMinutes: async.apply api.getMunites, toDay.clone().format("X"), toDay.clone().add(1, "day").format("X")
    periodMinutes: async.apply api.getMunites, currentPeriodStart.format("X"), currentPeriodEnd.subtract(OFFSET,"day").format("X")
  }
  (err, {todayMinutes, periodMinutes})->

    if err
      console.error err
      return process.exit err

    perDay = ((config.plan.hours * config.plan.days * 60) - (periodMinutes - todayMinutes)) / (workDaysLeft + 1)

    result = {
      completed:
        period: Math.round(periodMinutes / (config.plan.hours * config.plan.days * 60) * 100)
        day: Math.round((todayMinutes / perDay) * 100)
      mustWork:
        days: workDaysLeft
        perDay: api.format(perDay, yes)
        today: api.format(perDay - todayMinutes)
      worked:
        today: api.format todayMinutes
        atPeriod: api.format periodMinutes
    }

    output = {
      title: "Отработано #{api.format todayMinutes, yes} (ост. #{result.mustWork.today}/#{result.mustWork.perDay})"
      subtitle: "Текущий план #{api.format config.plan.hours * config.plan.days * 60} Отработано: #{api.format periodMinutes}"
      message: """
          Ост. дней: #{workDaysLeft}, в день по плану: #{result.mustWork.perDay}
        """
    }

    process.stdout.write JSON.stringify output

    process.exit()
)


