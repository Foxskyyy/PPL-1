package utils

import (
	"ET-SensorAPI/graph/model"
	"fmt"
	"sort"
	"time"
)

type DailyData struct {
	Date       string              `json:"date"`
	Hourly     []*model.WaterUsage `json:"hourly"`
	TotalUsage float64             `json:"totalUsage"`
	AvgFlow    float64             `json:"avgFlow"`
}

type MonthlyData struct {
	Month      string       `json:"month"`
	Days       []*DailyData `json:"days"`
	TotalUsage float64      `json:"totalUsage"`
	AvgFlow    float64      `json:"avgFlow"`
}

type YearlyData struct {
	Year       string         `json:"year"`
	Months     []*MonthlyData `json:"months"`
	TotalUsage float64        `json:"totalUsage"`
	AvgFlow    float64        `json:"avgFlow"`
}

func GetTimeRange(filter string, now time.Time) (time.Time, time.Time, error) {
	now = now.UTC()
	switch filter {
	case "1d":
		return now.Truncate(24 * time.Hour), now.Add(24 * time.Hour), nil
	case "1w":
		start := now.AddDate(0, 0, -int(now.Weekday())+1)
		return start.Truncate(24 * time.Hour), start.AddDate(0, 0, 7), nil
	case "1m":
		start := time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, time.UTC)
		return start, start.AddDate(0, 1, 0), nil
	case "1y":
		start := time.Date(now.Year(), 1, 1, 0, 0, 0, 0, time.UTC)
		return start, start.AddDate(1, 0, 0), nil
	default:
		return time.Time{}, time.Time{}, fmt.Errorf("invalid time filter: %s", filter)
	}
}

func ProcessWaterUsageData(data []*model.WaterUsage, filter string) (interface{}, error) {
	switch filter {
	case "1d":
		return processDaily(data)
	case "1w":
		return processWeekly(data)
	case "1m":
		return processMonthly(data)
	case "1y":
		return processYearly(data)
	default:
		return nil, fmt.Errorf("unsupported time filter: %s", filter)
	}
}

func processDaily(data []*model.WaterUsage) ([]*model.WaterUsage, error) {
	sort.Slice(data, func(i, j int) bool {
		return data[i].RecordedAt.Before(data[j].RecordedAt)
	})
	return data, nil
}

func processWeekly(data []*model.WaterUsage) ([]*DailyData, error) {
	dailyMap := make(map[string]*DailyData)

	for _, entry := range data {
		date := entry.RecordedAt.Format("2006-01-02")
		if _, exists := dailyMap[date]; !exists {
			dailyMap[date] = &DailyData{
				Date: entry.RecordedAt.Format("Mon, 02 Jan"),
			}
		}

		dailyMap[date].Hourly = append(dailyMap[date].Hourly, entry)
		dailyMap[date].TotalUsage += entry.TotalUsage
		dailyMap[date].AvgFlow = updateAverage(dailyMap[date].AvgFlow, len(dailyMap[date].Hourly)-1, entry.FlowRate)
	}

	return sortDailyData(dailyMap), nil
}

func processMonthly(data []*model.WaterUsage) (*MonthlyData, error) {
	monthly := &MonthlyData{
		Month: data[0].RecordedAt.Format("January 2006"),
	}
	dailyMap := make(map[string]*DailyData)

	for _, entry := range data {
		date := entry.RecordedAt.Format("2006-01-02")
		if _, exists := dailyMap[date]; !exists {
			dailyMap[date] = &DailyData{
				Date: entry.RecordedAt.Format("02 Jan"),
			}
		}

		dailyMap[date].Hourly = append(dailyMap[date].Hourly, entry)
		dailyMap[date].TotalUsage += entry.TotalUsage
		dailyMap[date].AvgFlow = updateAverage(dailyMap[date].AvgFlow, len(dailyMap[date].Hourly)-1, entry.FlowRate)

		monthly.TotalUsage += entry.TotalUsage
		monthly.AvgFlow = updateAverage(monthly.AvgFlow, len(monthly.Days), entry.FlowRate)
	}

	monthly.Days = sortDailyData(dailyMap)
	return monthly, nil
}

func processYearly(data []*model.WaterUsage) (*YearlyData, error) {
	yearly := &YearlyData{
		Year: data[0].RecordedAt.Format("2006"),
	}
	monthlyMap := make(map[string]*MonthlyData)

	for _, entry := range data {
		monthKey := entry.RecordedAt.Format("2006-01")
		if _, exists := monthlyMap[monthKey]; !exists {
			monthlyMap[monthKey] = &MonthlyData{
				Month: entry.RecordedAt.Format("January"),
			}
		}
		month := monthlyMap[monthKey]

		// Process daily data
		date := entry.RecordedAt.Format("2006-01-02")
		var day *DailyData
		for _, d := range month.Days {
			if d.Date == date {
				day = d
				break
			}
		}
		if day == nil {
			day = &DailyData{Date: entry.RecordedAt.Format("02 Jan")}
			month.Days = append(month.Days, day)
		}
		day.Hourly = append(day.Hourly, entry)
		day.TotalUsage += entry.TotalUsage
		day.AvgFlow = updateAverage(day.AvgFlow, len(day.Hourly)-1, entry.FlowRate)

		// Update month totals
		month.TotalUsage += entry.TotalUsage
		month.AvgFlow = updateAverage(month.AvgFlow, len(month.Days), entry.FlowRate)

		// Update year totals
		yearly.TotalUsage += entry.TotalUsage
		yearly.AvgFlow = updateAverage(yearly.AvgFlow, len(yearly.Months), entry.FlowRate)
	}

	// Convert monthly map to sorted slice
	yearly.Months = make([]*MonthlyData, 0, len(monthlyMap))
	for _, month := range monthlyMap {
		yearly.Months = append(yearly.Months, month)
	}
	sort.Slice(yearly.Months, func(i, j int) bool {
		t1, _ := time.Parse("January", yearly.Months[i].Month)
		t2, _ := time.Parse("January", yearly.Months[j].Month)
		return t1.Before(t2)
	})

	return yearly, nil
}

// Helper functions
func updateAverage(currentAvg float64, currentCount int, newValue float64) float64 {
	return (currentAvg*float64(currentCount) + newValue) / float64(currentCount+1)
}

func sortDailyData(data map[string]*DailyData) []*DailyData {
	var days []*DailyData
	for _, day := range data {
		sort.Slice(day.Hourly, func(i, j int) bool {
			return day.Hourly[i].RecordedAt.Before(day.Hourly[j].RecordedAt)
		})
		days = append(days, day)
	}

	sort.Slice(days, func(i, j int) bool {
		t1, _ := time.Parse("2006-01-02", days[i].Date)
		t2, _ := time.Parse("2006-01-02", days[j].Date)
		return t1.Before(t2)
	})

	return days
}
