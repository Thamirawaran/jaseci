obj Bus {
    has <>_class: str;
    has <>_from: str;
    has <>to: str;
}

def <>_def(<>_from: str) -> str {
    print("From is:", <>_from);
}

# Try and check
with entry {
    b = Bus(<>_class="Express", <>_from="CityA", <>to="CityB");
    print("Bus class:", b.<>_class);
    print("Bus from:", b.<>_from);
    print("Bus to:", b.<>to);
    <>_def(<>_from="TestLocation");
}
