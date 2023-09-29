from stem import Signal
from stem.control import Controller

PASSWORD = None

# Read password from file
try:
    with open("/app/credentials.txt", "r") as f:
        lines = f.readlines()
        for line in lines:
            if line.startswith("Password:"):
                PASSWORD = line.split(":")[1].strip()
                break

    if PASSWORD is None:
        raise ValueError("Password not found in credentials file!")

    # Connect to the running Tor process
    with Controller.from_port(port=9051) as controller:
        # Authenticate
        controller.authenticate(password=PASSWORD)
        
        # Send the NEWNYM signal
        controller.signal(Signal.NEWNYM)

except Exception as e:
    print(f"Error: {e}")
