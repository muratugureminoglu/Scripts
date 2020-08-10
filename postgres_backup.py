import time, datetime, os

week = "Sunday"
def backup():
    d = datetime.datetime.now().strftime("%d-%m-%Y")
    day = time.strftime('%A')
    file_name = "/backup/postgres/xdb"
    if not os.path.exists(file_name):
        os.makedirs(file_name)
    if week != day:
        daily = os.popen("/usr/bin/pg_dump --exclude-table-data=rapor.log xdb |gzip -9 -c > /backup/postgres/xdb/xdb-{}.gz".format(d))
        return daily

    else:
        weekly = os.popen("/usr/bin/pg_dump xdb |gzip -9 -c > /backup/postgres/xdb/xdb-full-{}.gz".format(d))
        return weekly


backup()
