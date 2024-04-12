import re

exec_count = 0
submit_count = 0

jobs = []

for i in range(0,1000):
    jobs.append({
        "done": False,
        "submitted": False,
        "executed": False,
        "valueCompleted": False,
        "id": i
    })

with open("Saved/Session_Log.txt") as f:
    for line in f:
        x = re.findall(r"\d+", line)
        if "payload:" in line:
            exec_count += 1
            jobs[int(x[0])]["executed"] = True

        elif "creating" in line:
            submit_count += 1
            jobs[int(x[0])]["submitted"] = True
                

print("exec:",exec_count)
print("submit:",submit_count)

for j in jobs:
    if j["executed"] == False:
        print(j)
