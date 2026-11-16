import csv
import json
import re
import sys

if __name__ == "__main__":
    LOCALES_ROW = 0
    LANGUAGE_NAME_ROW = 1
    TRANSLATORS_CREDITS_ROW = 2
    TRANSLATORS_DISCORD_ROW = 3
    OUTDATED_TRANSLATIONS_ROW = 4

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
            elif row_number == LANGUAGE_NAME_ROW:
                for i in range(1, len(row)):
                    if row[i] != "":
                        localeStats[locales[i]]["name"] = row[i]
            elif row_number in [TRANSLATORS_CREDITS_ROW, TRANSLATORS_DISCORD_ROW]:
                new_rows.append(row)
                continue
            elif row_number == OUTDATED_TRANSLATIONS_ROW:
                continue
            # Check %s and %d count consistency across all languages. Very important
            percent_s_count = 0
            percent_d_count = 0
            # Check whether all keys for {} formatting are consistent across all languages
            formats = []
            # Process the rest of the csv
            for i in range(1, len(row)):
                # If the cell's translation is out-of-date (marked by a ! followed by two letters indicating the locale, then a new line)
                # empty it to use the default language (English)
                if row[i] != "":
                    outdated_marker = "!" + locales[i]
                    if row[i][0:3] == outdated_marker:
                        row[i] = ""
                    elif outdated_marker in row[i]:
                        row[i] = row[i][0:row[i].find(outdated_marker)-1]
                    if locales[i] == "en":
                        percent_s_count = row[i].count("%s")
                        percent_d_count = row[i].count("%d")
                        formats = re.findall("\\{(\\w+)\\}", row[i])
                    elif row[i] != "":
                        if percent_s_count != row[i].count("%s"):
                            print(locales[i] + " " + str(row_number) + " %s count mismatch")
                            row[i] == ""
                        if percent_d_count != row[i].count("%d"):
                            print(locales[i] + " " + str(row_number) + " %d count mismatch")
                            row[i] == ""
                        _formats = re.findall("\\{(\\w+)\\}", row[i])
                        if len(formats) != len(_formats):
                            print(locales[i] + " " + str(row_number) + " number of format keys inconsistent")
                        for j in range(len(_formats)):
                            key = _formats[j]
                            if key not in formats:
                                print(locales[i] + " " + str(row_number) + " format key '" + key + "' not present in original text")
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
