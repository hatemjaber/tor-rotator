import os
from stem import Signal
from stem.control import Controller

# Start with the base control port, and increment by 2 for each instance to avoid conflicts
BASE_CONTROL_PORT = 9051

# Get the number of Tor instances from an environment variable or default to 5
NUM_INSTANCES = int(os.environ.get('NUM_TOR_INSTANCES', 5))

# Initialize the password variable
PASSWORD = None

try:
    # Read the password from the credentials file
    with open("/app/credentials.txt", "r") as f:
        lines = f.readlines()
        for line in lines:
            if line.startswith("Password:"):
                PASSWORD = line.split(":")[1].strip()
                break

    # Raise an error if the password is not found
    if PASSWORD is None:
        raise ValueError("Password not found in credentials file!")

    # Loop through each Tor instance
    for i in range(NUM_INSTANCES):
        # Calculate the control port for the current Tor instance
        port = BASE_CONTROL_PORT + i * 2  # Increment by 2 to match the Bash script

        # Connect to the Tor controller
        with Controller.from_port(port=port) as controller:
            # Authenticate with the controller
            controller.authenticate(password=PASSWORD)

            # Signal the Tor controller to switch to a new identity
            controller.signal(Signal.NEWNYM)

except Exception as e:
    print(f"Error: {e}")
