How to use:

Prerequisites:
- Python installed
- R installed
- PostgreSQL installed and running


1. Python environment

From the `BusinessAnalytics` directory:

python -m venv venv
source venv/bin/activate   # or Windows: venv\Scripts\activate
pip install -r requirements.txt



2. R Setup (Shiny dashboard)

Navigate into the shiny_dashboard subfolder and open the R project by
double-clicking 'shiny_dashboard.Rproj'.

Then run the following commands in the R console:

install.packages("renv")
renv::restore()



3. Running the application

From the BusinessAnalytics directory open:

start_GUI_Sidebar.py


You may need to configure your database login on the HomePage when starting the GUI for the first time.
