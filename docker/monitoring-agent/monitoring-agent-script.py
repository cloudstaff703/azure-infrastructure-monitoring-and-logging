import os
import time

LOG_ANALYTICS_WORKSPACE_ID = os.environ.get('LOG_ANALYTICS_WORKSPACE_ID')
LOG_ANALYTICS_SHARED_KEY = os.environ.get('LOG_ANALYTICS_SHARED_KEY')

def main():
    while True:
        print(f"Monitoring using workspace ID: {LOG_ANALYTICS_WORKSPACE_ID} and key: {LOG_ANALYTICS_SHARED_KEY}")
        time.sleep(60)

if __name__ == "__main__":
    main()