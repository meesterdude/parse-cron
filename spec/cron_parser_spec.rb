require "time"
require "./spec/spec_helper"
require "cron_parser"
require "date"

def parse_date(str)
  dt = DateTime.strptime(str, "%Y-%m-%d %H:%M")
  Time.local(dt.year, dt.month, dt.day, dt.hour, dt.min, 0)
end

describe "CronParser#parse_element" do
  [
    ["*", 0..59, (0..59).to_a],
    ["*/10", 0..59, [0, 10, 20, 30, 40, 50]],
    ["10", 0..59, [10]],
    ["10,30", 0..59, [10, 30]],
    ["10-15", 0..59, [10, 11, 12, 13, 14, 15]],
    ["10-40/10", 0..59, [10, 20, 30, 40]],
  ].each do |element, range, expected|
    it "should return #{expected} for '#{element}' when range is #{range}" do
      parser = CronParser.new('* * * * *')
      parser.parse_element(element, range).first.to_a.sort.should == expected.sort
    end
  end
end

describe "Normal matching" do
  describe "CronParser#next" do
    [
      ["* * * * *",             "2011-08-15 12:00",  "2011-08-15 12:01",1],
      ["* * * * *",             "2011-08-15 02:25",  "2011-08-15 02:26",1],
      ["* * * * *",             "2011-08-15 02:59",  "2011-08-15 03:00",1],
      ["*/15 * * * *",          "2011-08-15 02:02",  "2011-08-15 02:15",1],
      ["*/15,25 * * * *",       "2011-08-15 02:15",  "2011-08-15 02:25",1],
      ["30 3,6,9 * * *",        "2011-08-15 02:15",  "2011-08-15 03:30",1],
      ["30 9 * * *",            "2011-08-15 10:15",  "2011-08-16 09:30",1],
      ["30 9 * * *",            "2011-08-31 10:15",  "2011-09-01 09:30",1],
      ["30 9 * * *",            "2011-09-30 10:15",  "2011-10-01 09:30",1],
      ["0 9 * * *",             "2011-12-31 10:15",  "2012-01-01 09:00",1],
      ["* * 12 * *",            "2010-04-15 10:15",  "2010-05-12 00:00",1],
      ["* * * * 1,3",           "2010-04-15 10:15",  "2010-04-19 00:00",1],
      ["* * * * MON,WED",       "2010-04-15 10:15",  "2010-04-19 00:00",1],
      ["0 0 1 1 *",             "2010-04-15 10:15",  "2011-01-01 00:00",1],
      ["0 0 * * 1",             "2011-08-01 00:00",  "2011-08-08 00:00",1],
      ["0 0 * * 1",             "2011-07-25 00:00",  "2011-08-01 00:00",1],
      ["45 23 7 3 *",           "2011-01-01 00:00",  "2011-03-07 23:45",1],
      ["0 0 1 jun *",           "2013-05-14 11:20",  "2013-06-01 00:00",1],
      ["0 0 1 may,jul *",       "2013-05-14 15:00",  "2013-07-01 00:00",1],
      ["0 0 1 MAY,JUL *",       "2013-05-14 15:00",  "2013-07-01 00:00",1],
      ["40 5 * * *",            "2014-02-01 15:56",  "2014-02-02 05:40",1],
      ["0 5 * * 1",             "2014-02-01 15:56",  "2014-02-03 05:00",1],
      ["10 8 15 * *",           "2014-02-01 15:56",  "2014-02-15 08:10",1],
      ["50 6 * * 1",            "2014-02-01 15:56",  "2014-02-03 06:50",1],
      ["1 2 * apr mOn",         "2014-02-01 15:56",  "2014-04-07 02:01",1],
      ["1 2 3 4 7",             "2014-02-01 15:56",  "2014-04-03 02:01",1],
      ["1 2 3 4 7",             "2014-04-04 15:56",  "2014-04-06 02:01",1],
      ["1-20/3 * * * *",        "2014-02-01 15:56",  "2014-02-01 16:01",1],
      ["1,2,3 * * * *",         "2014-02-01 15:56",  "2014-02-01 16:01",1],
      ["1-9,15-30 * * * *",     "2014-02-01 15:56",  "2014-02-01 16:01",1],
      ["1-9/3,15-30/4 * * * *", "2014-02-01 15:56",  "2014-02-01 16:01",1],
      ["1 2 3 jan mon",         "2014-02-01 15:56",  "2015-01-03 02:01",1],
      ["1 2 3 4 mON",           "2014-02-01 15:56",  "2014-04-03 02:01",1],
      ["1 2 3 jan 5",           "2014-02-01 15:56",  "2015-01-02 02:01",1],
      ["@yearly",               "2014-02-01 15:56",  "2015-01-01 00:00",1],
      ["@annually",             "2014-02-01 15:56",  "2015-01-01 00:00",1],
      ["@monthly",              "2014-02-01 15:56",  "2014-03-01 00:00",1],
      ["@weekly",               "2014-02-01 15:56",  "2014-02-02 00:00",1],
      ["@daily",                "2014-02-01 15:56",  "2014-02-02 00:00",1],
      ["@midnight",             "2014-02-01 15:56",  "2014-02-02 00:00",1],
      ["@hourly",               "2014-02-01 15:56",  "2014-02-01 16:00",1],
      ["*/3 * * * *",           "2014-02-01 15:56",  "2014-02-01 15:57",1],
      ["0 5 * 2,3 *",           "2014-02-01 15:56",  "2014-02-02 05:00",1],
      ["15-59/15 * * * *",      "2014-02-01 15:56",  "2014-02-01 16:15",1],
      ["15-59/15 * * * *",      "2014-02-01 15:00",  "2014-02-01 15:15",1],
      ["15-59/15 * * * *",      "2014-02-01 15:01",  "2014-02-01 15:15",1],
      ["15-59/15 * * * *",      "2014-02-01 15:16",  "2014-02-01 15:30",1],
      ["15-59/15 * * * *",      "2014-02-01 15:26",  "2014-02-01 15:30",1],
      ["15-59/15 * * * *",      "2014-02-01 15:36",  "2014-02-01 15:45",1],
      ["15-59/15 * * * *",      "2014-02-01 15:45",  "2014-02-01 16:15",4],
      ["15-59/15 * * * *",      "2014-02-01 15:46",  "2014-02-01 16:15",3],
      ["15-59/15 * * * *",      "2014-02-01 15:46",  "2014-02-01 16:15",2],
    ].each do |line, now, expected_next,num|
      it "returns #{expected_next} for '#{line}' when now is #{now}" do
        parsed_now = parse_date(now)
        expected = parse_date(expected_next)
        parser = CronParser.new(line)
        parser.next(parsed_now).xmlschema.should == expected.xmlschema
      end
      it "returns the expected class" do
        parsed_now = parse_date(now)
        expected = parse_date(expected_next)
        parser = CronParser.new(line)
        result = parser.next(parsed_now,num)
        result.class.to_s.should == (num > 1 ? 'Array' : 'Time')
      end
      it "returns the expected count" do
        parsed_now = parse_date(now)
        expected = parse_date(expected_next)
        parser = CronParser.new(line)
        result = parser.next(parsed_now,num)
        if result.class.to_s == 'Array'
          result.size.should == num
        else
          result.class.to_s.should == 'Time'
        end
      end
    end

    describe "without strict matching" do
      it "returns any friday OR 13th" do
        upcoming = CronParser.new("0 1 13 * 5").next(Time.now, 10)
        upcoming.all?{|t| t.mday == 13 || t.wday == 5}.should be true
      end
    end
    describe "with strict matching" do
      it "returns only friday the 13th" do
        upcoming = CronParser.new("0 1 13 * 5", Time, true).next(Time.now, 10)
        upcoming.all?{|t| t.mday == 13 && t.wday == 5}.should be true
      end
    end
  end

  describe "CronParser#last" do
    [
      ["* * * * *",             "2011-08-15 12:00",  "2011-08-15 11:59"],
      ["* * * * *",             "2011-08-15 02:25",  "2011-08-15 02:24"],
      ["* * * * *",             "2011-08-15 03:00",  "2011-08-15 02:59"],
      ["*/15 * * * *",          "2011-08-15 02:02",  "2011-08-15 02:00"],
      ["*/15,45 * * * *",       "2011-08-15 02:55",  "2011-08-15 02:45"],
      ["*/15,25 * * * *",       "2011-08-15 02:35",  "2011-08-15 02:30"],
      ["30 3,6,9 * * *",        "2011-08-15 02:15",  "2011-08-14 09:30"],
      ["30 9 * * *",            "2011-08-15 10:15",  "2011-08-15 09:30"],
      ["30 9 * * *",            "2011-09-01 08:15",  "2011-08-31 09:30"],
      ["30 9 * * *",            "2011-10-01 08:15",  "2011-09-30 09:30"],
      ["0 9 * * *",             "2012-01-01 00:15",  "2011-12-31 09:00"],
      ["* * 12 * *",            "2010-04-15 10:15",  "2010-04-12 23:59"],
      ["* * * * 1,3",           "2010-04-15 10:15",  "2010-04-14 23:59"],
      ["* * * * MON,WED",       "2010-04-15 10:15",  "2010-04-14 23:59"],
      ["0 0 1 1 *",             "2010-04-15 10:15",  "2010-01-01 00:00"],
      ["0 0 1 jun *",           "2013-05-14 11:20",  "2012-06-01 00:00"],
      ["0 0 1 may,jul *",       "2013-05-14 15:00",  "2013-05-01 00:00"],
      ["0 0 1 MAY,JUL *",       "2013-05-14 15:00",  "2013-05-01 00:00"],
      ["40 5 * * *",            "2014-02-01 15:56",  "2014-02-01 05:40"],
      ["0 5 * * 1",             "2014-02-01 15:56",  "2014-01-27 05:00"],
      ["10 8 15 * *",           "2014-02-01 15:56",  "2014-01-15 08:10"],
      ["50 6 * * 1",            "2014-02-01 15:56",  "2014-01-27 06:50"],
      ["1 2 * apr mOn",         "2014-02-01 15:56",  "2013-04-29 02:01"],
      ["1 2 3 4 7",             "2014-02-01 15:56",  "2013-04-28 02:01"],
      ["1 2 3 4 7",             "2014-04-04 15:56",  "2014-04-03 02:01"],
      ["1-20/3 * * * *",        "2014-02-01 15:56",  "2014-02-01 15:19"],
      ["1,2,3 * * * *",         "2014-02-01 15:56",  "2014-02-01 15:03"],
      ["1-9,15-30 * * * *",     "2014-02-01 15:56",  "2014-02-01 15:30"],
      ["1-9/3,15-30/4 * * * *", "2014-02-01 15:56",  "2014-02-01 15:27"],
      ["1 2 3 jan mon",         "2014-02-01 15:56",  "2014-01-27 02:01"],
      ["1 2 3 4 mON",           "2014-02-01 15:56",  "2013-04-29 02:01"],
      ["1 2 3 jan 5",           "2014-02-01 15:56",  "2014-01-31 02:01"],
      ["@yearly",               "2014-02-01 15:56",  "2014-01-01 00:00"],
      ["@annually",             "2014-02-01 15:56",  "2014-01-01 00:00"],
      ["@monthly",              "2014-02-01 15:56",  "2014-02-01 00:00"],
      ["@weekly",               "2014-02-01 15:56",  "2014-01-26 00:00"],
      ["@daily",                "2014-02-01 15:56",  "2014-02-01 00:00"],
      ["@midnight",             "2014-02-01 15:56",  "2014-02-01 00:00"],
      ["@hourly",               "2014-02-01 15:56",  "2014-02-01 15:00"],
      ["*/3 * * * *",           "2014-02-01 15:56",  "2014-02-01 15:54"],
      ["0 5 * 2,3 *",           "2014-02-01 15:56",  "2014-02-01 05:00"],
      ["15-59/15 * * * *",      "2014-02-01 15:56",  "2014-02-01 15:45"],
      ["15-59/15 * * * *",      "2014-02-01 15:00",  "2014-02-01 14:45"],
      ["15-59/15 * * * *",      "2014-02-01 15:01",  "2014-02-01 14:45"],
      ["15-59/15 * * * *",      "2014-02-01 15:16",  "2014-02-01 15:15"],
      ["15-59/15 * * * *",      "2014-02-01 15:26",  "2014-02-01 15:15"],
      ["15-59/15 * * * *",      "2014-02-01 15:36",  "2014-02-01 15:30"],
      ["15-59/15 * * * *",      "2014-02-01 15:45",  "2014-02-01 15:30"],
      ["15-59/15 * * * *",      "2014-02-01 15:46",  "2014-02-01 15:45"],
    ].each do |line, now, expected_next|
      it "should return #{expected_next} for '#{line}' when now is #{now}" do
        now = parse_date(now)
        expected_next = parse_date(expected_next)
        parser = CronParser.new(line)
        parser.last(now).should == expected_next
      end
    end
  end
end

describe "Strict matching" do
  describe "CronParser#next" do
    [
      ["* * * * *",             "2011-08-15 12:00",  "2011-08-15 12:01",1],
      ["* * * * *",             "2011-08-15 02:25",  "2011-08-15 02:26",1],
      ["* * * * *",             "2011-08-15 02:59",  "2011-08-15 03:00",1],
      ["*/15 * * * *",          "2011-08-15 02:02",  "2011-08-15 02:15",1],
      ["*/15,25 * * * *",       "2011-08-15 02:15",  "2011-08-15 02:25",1],
      ["30 3,6,9 * * *",        "2011-08-15 02:15",  "2011-08-15 03:30",1],
      ["30 9 * * *",            "2011-08-15 10:15",  "2011-08-16 09:30",1],
      ["30 9 * * *",            "2011-08-31 10:15",  "2011-09-01 09:30",1],
      ["30 9 * * *",            "2011-09-30 10:15",  "2011-10-01 09:30",1],
      ["0 9 * * *",             "2011-12-31 10:15",  "2012-01-01 09:00",1],
      ["* * 12 * *",            "2010-04-15 10:15",  "2010-05-12 00:00",1],
      ["* * * * 1,3",           "2010-04-15 10:15",  "2010-04-19 00:00",1],
      ["* * * * MON,WED",       "2010-04-15 10:15",  "2010-04-19 00:00",1],
      ["0 0 1 1 *",             "2010-04-15 10:15",  "2011-01-01 00:00",1],
      ["0 0 * * 1",             "2011-08-01 00:00",  "2011-08-08 00:00",1],
      ["0 0 * * 1",             "2011-07-25 00:00",  "2011-08-01 00:00",1],
      ["45 23 7 3 *",           "2011-01-01 00:00",  "2011-03-07 23:45",1],
      ["0 0 1 jun *",           "2013-05-14 11:20",  "2013-06-01 00:00",1],
      ["0 0 1 may,jul *",       "2013-05-14 15:00",  "2013-07-01 00:00",1],
      ["0 0 1 MAY,JUL *",       "2013-05-14 15:00",  "2013-07-01 00:00",1],
      ["40 5 * * *",            "2014-02-01 15:56",  "2014-02-02 05:40",1],
      ["0 5 * * 1",             "2014-02-01 15:56",  "2014-02-03 05:00",1],
      ["10 8 15 * *",           "2014-02-01 15:56",  "2014-02-15 08:10",1],
      ["50 6 * * 1",            "2014-02-01 15:56",  "2014-02-03 06:50",1],
      ["1 2 * apr mOn",         "2014-02-01 15:56",  "2014-04-07 02:01",1],
      ["1 2 3 4 7",             "2014-02-01 15:56",  "2016-04-03 02:01",1],
      ["1-20/3 * * * *",        "2014-02-01 15:56",  "2014-02-01 16:01",1],
      ["1,2,3 * * * *",         "2014-02-01 15:56",  "2014-02-01 16:01",1],
      ["1-9,15-30 * * * *",     "2014-02-01 15:56",  "2014-02-01 16:01",1],
      ["1-9/3,15-30/4 * * * *", "2014-02-01 15:56",  "2014-02-01 16:01",1],
      ["1 2 3 jan mon",         "2014-02-01 15:56",  "2022-01-03 02:01",1],
      ["1 2 3 4 mON",           "2014-02-01 15:56",  "2017-04-03 02:01",1],
      ["1 2 3 jan 5",           "2014-02-01 15:56",  "2020-01-03 02:01",1],
      ["@yearly",               "2014-02-01 15:56",  "2015-01-01 00:00",1],
      ["@annually",             "2014-02-01 15:56",  "2015-01-01 00:00",1],
      ["@monthly",              "2014-02-01 15:56",  "2014-03-01 00:00",1],
      ["@weekly",               "2014-02-01 15:56",  "2014-02-02 00:00",1],
      ["@daily",                "2014-02-01 15:56",  "2014-02-02 00:00",1],
      ["@midnight",             "2014-02-01 15:56",  "2014-02-02 00:00",1],
      ["@hourly",               "2014-02-01 15:56",  "2014-02-01 16:00",1],
      ["*/3 * * * *",           "2014-02-01 15:56",  "2014-02-01 15:57",1],
      ["0 5 * 2,3 *",           "2014-02-01 15:56",  "2014-02-02 05:00",1],
      ["15-59/15 * * * *",      "2014-02-01 15:56",  "2014-02-01 16:15",1],
      ["15-59/15 * * * *",      "2014-02-01 15:00",  "2014-02-01 15:15",1],
      ["15-59/15 * * * *",      "2014-02-01 15:01",  "2014-02-01 15:15",1],
      ["15-59/15 * * * *",      "2014-02-01 15:16",  "2014-02-01 15:30",1],
      ["15-59/15 * * * *",      "2014-02-01 15:26",  "2014-02-01 15:30",1],
      ["15-59/15 * * * *",      "2014-02-01 15:36",  "2014-02-01 15:45",1],
      ["15-59/15 * * * *",      "2014-02-01 15:45",  "2014-02-01 16:15",4],
      ["15-59/15 * * * *",      "2014-02-01 15:46",  "2014-02-01 16:15",3],
      ["15-59/15 * * * *",      "2014-02-01 15:46",  "2014-02-01 16:15",2],
    ].each do |line, now, expected_next,num|
      it "returns #{expected_next} for '#{line}' when now is #{now}" do
        parsed_now = parse_date(now)
        expected = parse_date(expected_next)
        parser = CronParser.new(line,Time,true)
        parser.next(parsed_now).xmlschema.should == expected.xmlschema
      end
      it "returns the expected class" do
        parsed_now = parse_date(now)
        expected = parse_date(expected_next)
        parser = CronParser.new(line,Time,true)
        result = parser.next(parsed_now,num)
        result.class.to_s.should == (num > 1 ? 'Array' : 'Time')
      end
      it "returns the expected count" do
        parsed_now = parse_date(now)
        expected = parse_date(expected_next)
        parser = CronParser.new(line,Time,true)
        result = parser.next(parsed_now,num)
        if result.class.to_s == 'Array'
          result.size.should == num
        else
          result.class.to_s.should == 'Time'
        end
      end
    end
  end

  describe "CronParser#last" do
    [
      ["* * * * *",             "2011-08-15 12:00",  "2011-08-15 11:59"],
      ["* * * * *",             "2011-08-15 02:25",  "2011-08-15 02:24"],
      ["* * * * *",             "2011-08-15 03:00",  "2011-08-15 02:59"],
      ["*/15 * * * *",          "2011-08-15 02:02",  "2011-08-15 02:00"],
      ["*/15,45 * * * *",       "2011-08-15 02:55",  "2011-08-15 02:45"],
      ["*/15,25 * * * *",       "2011-08-15 02:35",  "2011-08-15 02:30"],
      ["30 3,6,9 * * *",        "2011-08-15 02:15",  "2011-08-14 09:30"],
      ["30 9 * * *",            "2011-08-15 10:15",  "2011-08-15 09:30"],
      ["30 9 * * *",            "2011-09-01 08:15",  "2011-08-31 09:30"],
      ["30 9 * * *",            "2011-10-01 08:15",  "2011-09-30 09:30"],
      ["0 9 * * *",             "2012-01-01 00:15",  "2011-12-31 09:00"],
      ["* * 12 * *",            "2010-04-15 10:15",  "2010-04-12 23:59"],
      ["* * * * 1,3",           "2010-04-15 10:15",  "2010-04-14 23:59"],
      ["* * * * MON,WED",       "2010-04-15 10:15",  "2010-04-14 23:59"],
      ["0 0 1 1 *",             "2010-04-15 10:15",  "2010-01-01 00:00"],
      ["0 0 1 jun *",           "2013-05-14 11:20",  "2012-06-01 00:00"],
      ["0 0 1 may,jul *",       "2013-05-14 15:00",  "2013-05-01 00:00"],
      ["0 0 1 MAY,JUL *",       "2013-05-14 15:00",  "2013-05-01 00:00"],
      ["40 5 * * *",            "2014-02-01 15:56",  "2014-02-01 05:40"],
      ["0 5 * * 1",             "2014-02-01 15:56",  "2014-01-27 05:00"],
      ["10 8 15 * *",           "2014-02-01 15:56",  "2014-01-15 08:10"],
      ["50 6 * * 1",            "2014-02-01 15:56",  "2014-01-27 06:50"],
      ["1 2 * apr mOn",         "2014-02-01 15:56",  "2013-04-29 02:01"],
      ["1 2 3 4 7",             "2014-02-01 15:56",  "2011-04-03 02:01"],
      ["1-20/3 * * * *",        "2014-02-01 15:56",  "2014-02-01 15:19"],
      ["1,2,3 * * * *",         "2014-02-01 15:56",  "2014-02-01 15:03"],
      ["1-9,15-30 * * * *",     "2014-02-01 15:56",  "2014-02-01 15:30"],
      ["1-9/3,15-30/4 * * * *", "2014-02-01 15:56",  "2014-02-01 15:27"],
      ["1 2 3 jan mon",         "2014-02-01 15:56",  "2011-01-03 02:01"],
      ["1 2 3 4 mON",           "2014-02-01 15:56",  "2006-04-03 02:01"],
      ["1 2 3 jan 5",           "2014-02-01 15:56",  "2003-01-03 02:01"],
      ["@yearly",               "2014-02-01 15:56",  "2014-01-01 00:00"],
      ["@annually",             "2014-02-01 15:56",  "2014-01-01 00:00"],
      ["@monthly",              "2014-02-01 15:56",  "2014-02-01 00:00"],
      ["@weekly",               "2014-02-01 15:56",  "2014-01-26 00:00"],
      ["@daily",                "2014-02-01 15:56",  "2014-02-01 00:00"],
      ["@midnight",             "2014-02-01 15:56",  "2014-02-01 00:00"],
      ["@hourly",               "2014-02-01 15:56",  "2014-02-01 15:00"],
      ["*/3 * * * *",           "2014-02-01 15:56",  "2014-02-01 15:54"],
      ["0 5 * 2,3 *",           "2014-02-01 15:56",  "2014-02-01 05:00"],
      ["15-59/15 * * * *",      "2014-02-01 15:56",  "2014-02-01 15:45"],
      ["15-59/15 * * * *",      "2014-02-01 15:00",  "2014-02-01 14:45"],
      ["15-59/15 * * * *",      "2014-02-01 15:01",  "2014-02-01 14:45"],
      ["15-59/15 * * * *",      "2014-02-01 15:16",  "2014-02-01 15:15"],
      ["15-59/15 * * * *",      "2014-02-01 15:26",  "2014-02-01 15:15"],
      ["15-59/15 * * * *",      "2014-02-01 15:36",  "2014-02-01 15:30"],
      ["15-59/15 * * * *",      "2014-02-01 15:45",  "2014-02-01 15:30"],
      ["15-59/15 * * * *",      "2014-02-01 15:46",  "2014-02-01 15:45"],
    ].each do |line, now, expected_next|
      it "should return #{expected_next} for '#{line}' when now is #{now}" do
        now = parse_date(now)
        expected_next = parse_date(expected_next)
        parser = CronParser.new(line,Time,true)
        parser.last(now).should == expected_next
      end
    end
  end
end

describe "CronParser#new" do
  it 'should not raise error when given a valid cronline' do
    expect { CronParser.new('30 * * * *') }.not_to raise_error
  end

  it 'should raise error when given an invalid cronline' do
    expect { CronParser.new('* * * *') }.to raise_error('not a valid cronline')
  end
end

describe "time source" do
  it "should use an alternate specified time source" do
    ExtendedTime = Class.new(Time)
    ExtendedTime.should_receive(:local).once
    CronParser.new("* * * * *",ExtendedTime).next
  end
end
