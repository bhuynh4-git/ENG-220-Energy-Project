import streamlit as st
from pathlib import Path

st.set_page_config(page_title="Jemez Coop & Sandoval Landfill", layout="wide")
st.title("⚡ Jemez Mountains Electric Coop & Sandoval County Landfill")

# 1. Check both the current folder and the 'Graphs' subfolder for local .png files
CURRENT_DIR = Path(__file__).parent
GRAPHS_DIR = CURRENT_DIR if CURRENT_DIR.name == "Graphs" else CURRENT_DIR / "Graphs"

png_files = sorted(GRAPHS_DIR.glob("*.png"))
if not png_files:
    png_files = sorted(CURRENT_DIR.glob("*.png"))

# 2. Display local .png files if found
if png_files:
    tab_names = [f"📊 {img.stem.replace('_', ' ')}" for img in png_files]
    tabs = st.tabs(tab_names)

    for tab, img_path in zip(tabs, png_files):
        with tab:
            st.subheader(img_path.stem.replace("_", " "))
            st.image(str(img_path), use_container_width=True)

# 3. Direct GitHub URL Fallback (loads directly from your GitHub link!)
else:
    RAW_GITHUB_BASE = "https://raw.githubusercontent.com/bhuynh4-git/ENG-220-Energy-Project/main/Graphs"
    
    # List your exact PNG file names in your GitHub 'Graphs' folder here:
    github_images = [
        "Sales.png",
        # As you upload more screenshots to GitHub/Graphs, add their names here if needed:
        # "Reliability.png",
        # "Operational.png",
        # "Territory.png",
        # "Landfill.png",
    ]

    tabs = st.tabs([f"📊 {name.replace('.png', '').replace('_', ' ')}" for name in github_images])
    for tab, img_name in zip(tabs, github_images):
        with tab:
            st.subheader(img_name.replace(".png", "").replace("_", " "))
            st.image(f"{RAW_GITHUB_BASE}/{img_name}", use_container_width=True)
