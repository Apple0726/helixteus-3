import csv
import json
import sys

if __name__ == "__main__":
    LOCALES_ROW = 0
    TRANSLATORS_CREDITS_ROW = 1
    TRANSLATORS_DISCORD_ROW = 2

    file_name = sys.argv[1]

    new_rows = []
    locales = ["alias"]
    localeStats = {}
    with open(file_name, newline='') as csvfile:
        reader = csv.reader(csvfile)
        first_row = True
        row_number = -1
        for row in reader:
            row_number += 1
            row.pop(1) # Remove comments column
            # Process csv header lines
            if row_number == LOCALES_ROW:
                for locale in row:
                    if locale != "":
                        locales.append(locale)
                        localeStats[locale] = {}
                        localeStats[locale]["lines"] = 0
                        localeStats[locale]["words"] = 0
                        localeStats[locale]["chars"] = 0
                new_rows.append(row)
                continue
            elif row_number in [TRANSLATORS_CREDITS_ROW, TRANSLATORS_DISCORD_ROW]:
                new_rows.append(row)
                continue
            
            # Process the rest of the csv
            for i in range(1, len(row)):
                # If the cell's translation is out-of-date (marked by a ! followed by two letters indicating the locale, then a new line)
                # empty it to use the default language (English)
                if row[i] != "" and row[i][0] == "!" and row[i][3] == "\n":
                    row[i] = ""
                if row[i] != "":
                    localeStats[locales[i]]["lines"] += 1
                    localeStats[locales[i]]["words"] += len(row[i].split())
                    localeStats[locales[i]]["chars"] += len(row[i])
            new_rows.append(row)
    
    with open(file_name, 'w', newline='') as csvfile:
        writer = csv.writer(csvfile)
        for row in new_rows:
            writer.writerow(row)
    
    with open("localeStats.json", 'w', encoding='utf-8') as jsonFile:
        json.dump(localeStats, jsonFile, ensure_ascii=False, indent=4)