''' OFFENE TODOS IM FILE ABARBEITEN!!!

ALLGEMEINE TODOS:
[] Kommentare aufräumen + Docstring ergänzen
[x] Dropdown Menüs aus der DB
[x] Dropdown Menüs aus Backend-Liste 
[x] MotherClass einführen
[] delete_btn in allen Pages implementieren
[x] Worker implementieren 
[] Settings / PopUp Delete Button 

MIT MARVIN ABSTIMMEN:
[] wie wird die MatrikelNr. eingeführt/validiert?


'''
from database_worker import DatabaseWorker
import os 
import json
from PySide6.QtGui import QDoubleValidator, QIntValidator, QPixmap
from PySide6.QtWidgets import QComboBox, QDateEdit, QHBoxLayout, QWidget, QVBoxLayout, QLabel, QLineEdit, QPushButton, QFormLayout
from PySide6.QtCore import Signal, QDate, Qt


def dropdown_options_path():
    """loads the dropdown options path and returns it"""
    config_path = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),"dropdown_options.json")
    return config_path

def load_dropdown_options():
    """loads the dropdown-options from the JSON-File"""
    config_path = dropdown_options_path()

    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            return True, json.load(f), ""  # success, options, error_msg for reload_options 
    except FileNotFoundError:
        return False, {"study_programs": [], "semesters": []}, "dropdown_options.json not found!" # success, options, error_msg for reload_options
    except json.JSONDecodeError:
        return False, {"study_programs": [], "semesters": []}, "Invalid JSON in dropdown_options.json!" # success, options, error_msg for reload_options

def login_config_path():
    """ returns the path of the user_login_config.json file used for loggin into the database"""
    config_path = os.path.join(
    os.path.dirname(os.path.abspath(__file__)),"user_login_config.json")
    return config_path

def load_login_config():
    """Loads the login config from the JSON file"""
    config_path = login_config_path()
    try:
        with open(config_path, 'r', encoding='utf-8') as f:
            return True, json.load(f), ""
    except FileNotFoundError:
        return False, {}, "user_login_config.json not found!"
    except json.JSONDecodeError:
        return False, {}, "Invalid JSON in user_login_config.json!"


class BasePage(QWidget):
    data_changed = Signal(dict)
    status_message = Signal(str, int)
    
    def __init__(self, title):
        super().__init__()
        self.base_path = os.path.dirname(os.path.abspath(__file__)) 
        self.image_path = os.path.join(self.base_path, "Images")
        self.data = {}  # Temporärer Datenspeicher
        self.title = title
        self.setup_base_ui()


    def setup_base_ui(self):
        self.main_layout = QVBoxLayout()
        
        # Header hinzufügen
        header = self.create_header(self.title)
        self.main_layout.addLayout(header)
        
        # Trennlinie
        separator = QLabel()
        separator.setStyleSheet("QLabel { border-bottom: 2px solid #bdc3c7; }")
        separator.setFixedHeight(2)
        self.main_layout.addWidget(separator)
        self.main_layout.addSpacing(20)
        
        # Content-Bereich (wird von Unterklassen gefüllt)
        self.content_layout = QVBoxLayout()
        self.main_layout.addLayout(self.content_layout)
        
        self.setLayout(self.main_layout)
    
    def create_header(self, title):
        """Erstellt den Header mit Titel und Bild"""
        header_layout = QHBoxLayout()
        
        title_label = QLabel(title)
        title_label.setStyleSheet("""
            QLabel {
                font-size: 24px;
                font-weight: bold;
                color: #0073B9;
            }
        """)
        
        image_label = QLabel()
        pixmap = QPixmap(os.path.join(self.image_path, "Header.png"))
        scaled_pixmap = pixmap.scaled(100, 100, Qt.AspectRatioMode.KeepAspectRatio, Qt.TransformationMode.SmoothTransformation)
        image_label.setPixmap(scaled_pixmap)
        
        header_layout.addWidget(title_label)
        header_layout.addStretch()
        header_layout.addWidget(image_label)
        
        return header_layout
    
    def setup_ui(self):
        """Has to be implemented by subclass"""
        raise NotImplementedError("Unterklassen müssen setup_ui() implementieren")
    
    def save_data(self):
        """Has to be implemented by subclass"""
        raise NotImplementedError("Unterklassen müssen save_data() implementieren")
    
    def get_data(self):
        """Has to be implemented by subclass"""
        raise NotImplementedError("Unterklassen müssen get_data() implementieren")
    
    def clear_form(self):
        """Has to be implemented by subclass"""
        raise NotImplementedError("Unterklassen müssen clear_form() implementieren")


class HomePage(BasePage):
    """
    ToDos:
    [x] connect buttons
    [x] clear forms
    [x] emit status message
    [x] add semster layout
    [] add complete config settings logic 
    [] add how-to use
    
    """
    def __init__(self):
        super().__init__("TODO: Home Page & Settings")
        self.setup_ui()
        self.load_current_config()


    # TODO: UI Überarbeiten
    def setup_ui(self):
# === Database Connection Section ===
        db_section_label = QLabel("Database Connection")
        db_section_label.setStyleSheet("font-size: 16px; font-weight: bold; margin-top: 10px;")
        self.content_layout.addWidget(db_section_label)

        db_form_layout = QFormLayout()

        self.host_input = QLineEdit()
        self.host_input.setPlaceholderText("localhost")
        
        self.port_input = QLineEdit()
        self.port_input.setPlaceholderText("5432")
        port_validator = QIntValidator(1, 65535)
        self.port_input.setValidator(port_validator)

        self.database_input = QLineEdit()
        self.database_input.setPlaceholderText("db_exam_management")

        self.username_input = QLineEdit()
        self.username_input.setPlaceholderText("Your PostgreSQL username")

        self.password_input = QLineEdit()
        self.password_input.setPlaceholderText("Your PostgreSQL password")
        self.password_input.setEchoMode(QLineEdit.EchoMode.Password)

        db_form_layout.addRow("Host:", self.host_input)
        db_form_layout.addRow("Port:", self.port_input)
        db_form_layout.addRow("Database:", self.database_input)
        db_form_layout.addRow("Username:", self.username_input)
        db_form_layout.addRow("Password:", self.password_input)

        self.content_layout.addLayout(db_form_layout)

        # Buttons für DB-Config
        db_btn_layout = QHBoxLayout()
        self.save_config_btn = QPushButton("Save Connection")
        self.save_config_btn.clicked.connect(self.save_login_config)
        self.test_connection_btn = QPushButton("Test Connection")
        self.test_connection_btn.clicked.connect(self.test_connection)
        db_btn_layout.addWidget(self.save_config_btn)
        db_btn_layout.addWidget(self.test_connection_btn)
        self.content_layout.addLayout(db_btn_layout)

        # Trennlinie
        separator = QLabel()
        separator.setStyleSheet("QLabel { border-bottom: 1px solid #bdc3c7; margin: 15px 0; }")
        separator.setFixedHeight(2)
        self.content_layout.addWidget(separator)

        # === Dropdown Options Section ===
        dropdown_section_label = QLabel("Dropdown Options")
        dropdown_section_label.setStyleSheet("font-size: 16px; font-weight: bold; margin-top: 10px;")
        self.content_layout.addWidget(dropdown_section_label)

        self.semester_layout = QHBoxLayout()
        self.study_program_layout = QHBoxLayout()
        
        self.new_semester_label = QLabel("Add new semester:")
        self.new_semester_input = QLineEdit()
        self.new_semester_input.setPlaceholderText("e.g. SoSe 26 or WiSe 26/27")
        self.add_semester_btn = QPushButton("Add")
        self.add_semester_btn.clicked.connect(self.add_semester_btn_clicked)

        self.new_study_program_label = QLabel("Add new study / degree program:")
        self.new_study_program_input = QLineEdit()
        self.new_study_program_input.setPlaceholderText("e.g. Business Informatics (M.Sc.)")
        self.add_study_program_btn = QPushButton("Add")
        self.add_study_program_btn.clicked.connect(self.add_study_program_btn_clicked)

        self.semester_layout.addWidget(self.new_semester_label)
        self.semester_layout.addWidget(self.new_semester_input)
        self.semester_layout.addWidget(self.add_semester_btn)

        self.study_program_layout.addWidget(self.new_study_program_label)
        self.study_program_layout.addWidget(self.new_study_program_input)
        self.study_program_layout.addWidget(self.add_study_program_btn)

        self.content_layout.addLayout(self.semester_layout)
        self.content_layout.addLayout(self.study_program_layout)
        self.content_layout.addStretch()
        
    def load_current_config(self):
        """Loads current config values into the form fields"""
        success, config, error_msg = load_login_config()
        if success:
            self.host_input.setText(config.get("host", "localhost"))
            self.port_input.setText(str(config.get("port", 5432)))
            self.database_input.setText(config.get("database", ""))
            self.username_input.setText(config.get("username", ""))
            self.password_input.setText(config.get("password", ""))
        else:
            self.status_message.emit(f"Error loading config: {error_msg}", 5000)

    def save_login_config(self):
        """Saves the login config to the JSON file"""
        if not self.username_input.text().strip():
            self.status_message.emit("Please enter a username", 3000)
            return
        
        config = {
            "_comment1": "This file stores the login credentials for the local PostgreSQL database.",
            "_comment2": "Please enter your own username and password. Do not share them with others.",
            "username": self.username_input.text(),
            "password": self.password_input.text(),
            "_comment3": "These values usually do not need to be changed unless your local PostgreSQL setup differs.",
            "host": self.host_input.text() or "localhost",
            "port": int(self.port_input.text() or 5432),
            "database": self.database_input.text() or "db_exam_management"
        }

        try:
            with open(login_config_path(), 'w', encoding='utf-8') as f:
                json.dump(config, f, indent=4, ensure_ascii=False)
            self.status_message.emit("Database configuration saved successfully!", 3000)
        except Exception as e:
            self.status_message.emit(f"Error saving config: {e}", 5000)

    def test_connection(self):
        """Tests the database connection with current settings"""
        try:
            import psycopg2
            conn = psycopg2.connect(
                host=self.host_input.text() or "localhost",
                port=int(self.port_input.text() or 5432),
                database=self.database_input.text() or "db_exam_management",
                user=self.username_input.text(),
                password=self.password_input.text()
            )
            conn.close()
            self.status_message.emit("Connection successful!", 3000)
        except Exception as e:
            self.status_message.emit(f"Connection failed: {e}", 5000)


    def add_semester_btn_clicked(self):
        key = "semesters"
        value = self.new_semester_input.text()

        if not value:
            self.status_message.emit("Please enter a semester", 3000)
            return

        success = self.append_dropdown_options(key, value)
        if success:
            self.new_semester_input.clear()
            self.status_message.emit(f"Added {value} to Semesters", 3000)

    def add_study_program_btn_clicked(self):
        key = "study_programs"
        value = self.new_study_program_input.text()

        if not value:
            self.status_message.emit("Please enter a study program", 3000)
            return

        success = self.append_dropdown_options(key, value)
        if success: 
            self.new_study_program_input.clear()
            self.status_message.emit(f"Added {value} to study programs", 3000)

    def save_data(self):
        """Not used in HomePage - config is saved via save_login_config"""
        pass

    def get_data(self):
        """Returns current config data"""
        return {
            'host': self.host_input.text(),
            'port': self.port_input.text(),
            'database': self.database_input.text(),
            'username': self.username_input.text()
        }

    def clear_form(self):
        """Reloads the current config"""
        self.load_current_config()
        """Gibt aktuelle Formulardaten zurück (auch ungespeicherte)"""
        return {
            'first_name': self.first_name_input.text(),
            'last_name': self.last_name_input.text(),
            'birth_date': self.birth_date_input.text(),
            'matriculation_no': self.matriculation_no_input.text()
        }
    

    def append_dropdown_options(self, key: str, value: str):
        """
        Append dropdown-options in dropdown_options.json

        Args:
            key: fixed key from dropdown_options.json file
            value: the value that will be appended to the selected key-list
        
        Returns:
            True if successful, False otherwise
        """
        success, data, error_msg = load_dropdown_options()
        if success: 
            if key not in data:
                self.status_message.emit(f"Error: cannot append to list {key}", 5000)
                return False
            
            if value in data[key]:
                self.status_message.emit(f"'{value}' already exists in {key}", 3000)
                return False
            
            data[key].append(value)
            return self.save_dropdown_json(data)
        else: 
            self.status_message.emit(f"Error: {error_msg}", 5000)
            return False

    def save_dropdown_json(self, data: dict):
        """Saves appended dropdown_options.json file"""
        config_path = dropdown_options_path()
        try:
            with open(config_path, 'w', encoding='utf-8') as file:
                json.dump(data, file, indent=4, ensure_ascii=False)
                return True
        except Exception as e:
                self.status_message.emit(f"Error while saving Data to the list: {e}", 5000)
                return False





class GradePage(BasePage):

    def __init__(self):
        super().__init__("Grade Entry")
        self.setup_ui()
        self.reload_dropdowns() 
    
    def showEvent(self, event):
        """Gets called when switching to this tab/page"""
        super().showEvent(event)
        self.reload_dropdowns()

    def reload_dropdowns(self): #
        """Load students and exams from the database into dropdown menu-lists"""
        self.load_students()
        self.load_exams()

    def load_students(self):
        """Load students from students from the database"""
        query = """SELECT matriculation_number, first_name, last_name FROM student ORDER BY last_name, first_name"""
        self.student_worker = DatabaseWorker(query, fetch=True)
        self.student_worker.data_fetched.connect(self.on_students_loaded)
        self.student_worker.start()

    def on_students_loaded(self, success, rows, error_msg):
        """ Callback when students are loaded"""
        if not success: 
            self.status_message.emit(f"Error loading students: {error_msg}"),
            return

        self.student_input.clear()
        self.student_input.addItem("-- Select student --", None)

        for row in rows:
            matriculation_number, first_name, last_name = row
            display_text = f"{last_name}, {first_name}, ({matriculation_number})"
            self.student_input.addItem(display_text, matriculation_number)

    def load_exams(self):
        """Load exams from the database"""
        query = "SELECT pnr, title, semester, exam_date FROM exam ORDER BY title"
        self.exam_worker = DatabaseWorker(query, fetch=True)
        self.exam_worker.data_fetched.connect(self.on_exams_loaded)
        self.exam_worker.start()

    def on_exams_loaded(self, success, rows, error_msg):
        """Callback when exams are loaded"""
        if not success:
            self.status_message.emit(f"Error loading exams: {error_msg}", 5000)
            return
        
        self.exam_input.clear()
        self.exam_input.addItem("-- Select exam --", None)

        for row in rows:
            pnr, title, semester, exam_date = row
            display_text = f"{pnr} - {title} ({exam_date} | {semester})"
            self.exam_input.addItem(display_text, pnr)

    def setup_ui(self):
        form_layout = QFormLayout()
        
        self.student_input = QComboBox()
        self.exam_input = QComboBox()
        self.grade_input = QLineEdit()
        self.grade_input.setPlaceholderText("e.g. 1.3")
        grade_validator = QDoubleValidator(1.0, 6.0, 1)
        self.grade_input.setValidator(grade_validator)
        
        form_layout.addRow("Student:", self.student_input)
        form_layout.addRow("Exam", self.exam_input)
        form_layout.addRow("Grade:", self.grade_input)
        
        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.save_data)
        
        self.content_layout.addLayout(form_layout)
        self.content_layout.addWidget(save_btn)
        self.content_layout.addStretch()

    def save_data(self):
        if  self.student_input.currentIndex() == 0:
            self.status_message.emit("Please select a student", 2000)
            return
        if  self.exam_input.currentIndex() == 0:
            self.status_message.emit("Please select an exam", 2000)
            return
        if not self.grade_input.text().strip():
            self.status_message.emit(f"Please enter a grade", 2000)
            return
        
        matriculation_number = self.student_input.currentData()
        pnr = self.exam_input.currentData()

        query = """ INSERT INTO grade (matriculation_number, pnr, grade, grade_date) VALUES (%s, %s, %s, CURRENT_DATE)"""
        params = (
            matriculation_number,
            pnr, 
            float(self.grade_input.text().replace(',', '.'))
        )

        self.db_worker = DatabaseWorker(query, params)
        self.db_worker.finished.connect(self.on_save_finished)
        self.db_worker.start()
        self.status_message.emit("Saving...", 0) # TODO: das wird doch nie angezeigt...

        self.data = {
            'student': self.student_input.currentText(),
            'exam': self.exam_input.currentText(),
            'grade': self.grade_input.text()
        }
        
        self.data_changed.emit(self.data)
    
    def on_save_finished(self, success, message):
        if success: 
            self.status_message.emit(message, 2000)
            self.data = self.get_data()
            self.data_changed.emit(self.data)
            self.clear_form()

        else:
            if "grade_unique_student_exam" in message or "unique" in message.lower():
                self.status_message.emit("This student already has a grade for this exam! Delete the grade first to update it!", 5000) 
            else:
                self.status_message.emit(f"Error: {message}", 5000)          




    def get_data(self):
        """Return (unsaved) formulardata"""
        return {
            'student': self.student_input.currentText(),
            'exam': self.exam_input.currentText(),
            'grade': self.grade_input.text()
        }
    
    def clear_form(self):
        """delete input after saving successfully"""
        self.student_input.setCurrentIndex(0)
        self.exam_input.setCurrentIndex(0)
        self.grade_input.clear()


class StudentPage(BasePage):
   
    def __init__(self):
        super().__init__("Student Entry")
        self.setup_ui()

    def setup_ui(self):
        form_layout = QFormLayout()
        
        name_layout = QHBoxLayout()
        self.first_name_input = QLineEdit()
        self.first_name_input.setPlaceholderText("Firstname")
        self.last_name_input = QLineEdit()
        self.last_name_input.setPlaceholderText("Lastname")
        name_layout.addWidget(self.first_name_input)
        name_layout.addWidget(self.last_name_input)

        form_layout.addRow("Name:", name_layout)

        self.birth_date_input = QDateEdit()
        self.birth_date_input.setDisplayFormat("dd.MM.yyyy")
        self.birth_date_input.setDate(QDate.currentDate())
        self.birth_date_input.setCalendarPopup(True)
        
        self.matriculation_no_input = QLineEdit()
        matriculation_validator = QIntValidator(0, 999999999)
        self.matriculation_no_input.setValidator(matriculation_validator)

        form_layout.addRow("Date of Birth:", self.birth_date_input)
        form_layout.addRow("Matriculation Number:", self.matriculation_no_input)



        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.save_data)
        
        self.content_layout.addLayout(form_layout)
        self.content_layout.addWidget(save_btn)
        self.content_layout.addStretch()
        



    def save_data(self):
        if not self.first_name_input.text().strip():
            self.status_message.emit("Please enter a firstname", 2000)
            return
        if not self.last_name_input.text().strip():
            self.status_message.emit("Please enter a lastname", 2000)
            return
        if not self.matriculation_no_input.text().strip():
            self.status_message.emit("Please enter a matriculation number", 2000)
            return

        query = """
            INSERT INTO student (first_name, last_name, date_of_birth, matriculation_number)
            VALUES (%s, %s, %s, %s)
        """
        params = (
            self.first_name_input.text(),
            self.last_name_input.text(),
            self.birth_date_input.date().toString("yyyy-MM-dd"),
            self.matriculation_no_input.text()
        )
        
        # Worker-Thread starten
        self.db_worker = DatabaseWorker(query, params)
        self.db_worker.finished.connect(self.on_save_finished)
        self.db_worker.start()
        
        self.status_message.emit("Saving...", 0)
    
    def on_save_finished(self, success, message):
        if success:
            self.status_message.emit(message, 2000)
            self.data = self.get_data()
            self.data_changed.emit(self.data)
            self.clear_form()
        else:
            self.status_message.emit(message, 5000)
        
    
    def get_data(self):
        """Gibt aktuelle Formulardaten zurück (auch ungespeicherte)"""
        return {
            'first_name': self.first_name_input.text(),
            'last_name': self.last_name_input.text(),
            'birth_date': self.birth_date_input.text(),
            'matriculation_no': self.matriculation_no_input.text()
        }
    
    def clear_form(self):
        """Formular zurücksetzen nach erfolgreichem Speichern"""
        self.first_name_input.clear()
        self.last_name_input.clear()
        self.birth_date_input.clear()
        self.matriculation_no_input.clear()


class ExamPage(BasePage):

    
    def __init__(self):
        super().__init__("Exam Entry")
        self.setup_ui()
        self.reload_dropdowns()

    def showEvent(self, event):
        """ gets called when switching to this tab/page"""
        super().showEvent(event)
        self.reload_dropdowns()

    def reload_dropdowns(self):
        """reloads dropdown options from the JSON-file"""
        success, options, error_msg = load_dropdown_options()

        if not success:
            self.status_message.emit(f"Error: {error_msg}", 5000)
            return

        self.semester_input.clear()
        self.semester_input.addItem("-- Select semester --")
        self.semester_input.addItems(options.get("semesters", []))

        self.study_program_input.clear()
        self.study_program_input.addItem("--Select study program --")
        self.study_program_input.addItems(options.get("study_programs", []))

   
    def setup_ui(self):
        form_layout = QFormLayout()
              
        self.pnr_input = QLineEdit()
        self.pnr_input.setPlaceholderText("Exam number")

        self.exam_title_input = QLineEdit()
        self.exam_title_input.setPlaceholderText("Exam title")

        self.exam_date_input = QDateEdit()
        self.exam_date_input.setDisplayFormat("dd.MM.yyyy")
        self.exam_date_input.setCalendarPopup(True)


        #TODO: Kann die Zeile dann noch leer sein? - Errorhandling wenn "-- Select..."
        self.semester_input = QComboBox()


        #TODO: Auch das könnte ein Dropdown sein?! -> mega fehleranfällig
        self.study_program_input = QComboBox()


        form_layout.addRow("PNr:", self.pnr_input)
        form_layout.addRow("Title:", self.exam_title_input)
        form_layout.addRow("Date:", self.exam_date_input)
        form_layout.addRow("Semester:", self.semester_input)
        form_layout.addRow("Study program:", self.study_program_input)
        
        
        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.save_data)

        delete_btn = QPushButton("Delete")
        delete_btn.clicked.connect(self.delete_data)
        
        self.content_layout.addLayout(form_layout)
        self.content_layout.addWidget(save_btn)
        self.content_layout.addStretch()



    def save_data(self):
        if not self.pnr_input.text().strip():
            self.status_message.emit("Please enter an exam number", 2000)
            return
        if not self.exam_title_input.text().strip():
            self.status_message.emit("Please enter an exam title", 2000)
            return
        if not self.exam_date_input.text().strip():
            self.status_message.emit("Please enter an exam date", 2000)
            return
        if self.semester_input.currentIndex() == 0:
            self.status_message.emit("Please select a semester", 2000) #TODO: 'Select' oder 'Enter' je nach Dropdown oder nicht
            return
        if self.study_program_input.currentIndex() == 0: 
            self.status_message.emit("Please select a study program", 2000) #TODO: 'Select' oder 'Enter' je nach Dropdown oder nicht
            return
        

        query = """
            INSERT INTO exam (pnr, title, exam_date, semester, degree_program) 
            VALUES (%s, %s, %s, %s, %s)
        """

        params = (
            self.pnr_input.text(),
            self.exam_title_input.text(),
            self.exam_date_input.date().toString("yyyy-MM-dd"),
            self.semester_input.currentText(),
            self.study_program_input.currentText()
        )
        # Worker-Thread starten
        self.db_worker = DatabaseWorker(query, params)
        self.db_worker.finished.connect(self.on_save_finished)
        self.db_worker.start()
        
        self.status_message.emit("Saving...", 0)
    
    def on_save_finished(self, success, message):
        if success:
            self.status_message.emit(message, 2000)
            self.data = self.get_data()
            self.data_changed.emit(self.data)
            self.clear_form()
        else:
            self.status_message.emit(message, 5000)


    def get_data(self):
        """return (unsaved) formulardata"""
        return {
            'PNr': self.pnr_input.text(),
            'exam_title': self.exam_title_input.text(),
            'exam_date': self.exam_date_input.date().toString("yyyy-MM-dd"),
            'semester': self.semester_input.currentText(),
            'study_program': self.study_program_input.currentText()
        }
    
    def delete_data(self):
        if not self.pnr_input.text().strip():
            self.status_message.emit("Please enter an exam number (\"PNr\") to delete it", 2000) #TODO: separat aus nem Dropdown auswählen. 
            return
        

    def clear_form(self):
        """delete input after saving successfully"""
        self.pnr_input.clear()
        self.exam_title_input.clear()
        self.exam_date_input.clear()
        self.semester_input.setCurrentIndex(0)
        self.study_program_input.setCurrentIndex(0)


class StatsPage(BasePage):
    
    def __init__(self):
        super().__init__("Statistics")
        self.setup_ui()

    def setup_ui(self):

        form_layout = QFormLayout()
        
        name_layout = QHBoxLayout()
        self.first_name_input = QLineEdit()
        self.first_name_input.setPlaceholderText("Firstname")
        self.last_name_input = QLineEdit()
        self.last_name_input.setPlaceholderText("Lastname")
        name_layout.addWidget(self.first_name_input)
        name_layout.addWidget(self.last_name_input)

        form_layout.addRow("Name:", name_layout)

        self.birth_date_input = QDateEdit()
        self.birth_date_input.setDisplayFormat("dd.MM.yyyy")
        self.birth_date_input.setDate(QDate.currentDate())
        self.birth_date_input.setCalendarPopup(True)
        
        self.matriculation_no_input = QLineEdit()
        matriculation_validator = QIntValidator(0, 999999999)
        self.matriculation_no_input.setValidator(matriculation_validator)

        form_layout.addRow("Date of Birth:", self.birth_date_input)
        form_layout.addRow("Matriculation Number:", self.matriculation_no_input)



        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.save_data)
        
        self.content_layout.addLayout(form_layout)
        self.content_layout.addWidget(save_btn)
        self.content_layout.addStretch()



    def save_data(self):
        if not self.first_name_input.text().strip():
            self.status_message.emit("Please enter a firstname", 2000)
            return
        if not self.last_name_input.text().strip():
            self.status_message.emit("Please enter a lastname", 2000)
            return
        if not self.matriculation_no_input.text().strip():
            self.status_message.emit("Please enter a matriculation number", 2000)
            return

        self.data = {
            'first_name': self.first_name_input.text(),
            'last_name': self.last_name_input.text(),
            'birth_date': self.birth_date_input.text(),
            'matriculation_no': self.matriculation_no_input.text()
        }
        # Signal aussenden
        self.data_changed.emit(self.data)
        self.status_message.emit("Student Data saved succesfully!", 2000)
    
    def get_data(self):
        """Gibt aktuelle Formulardaten zurück (auch ungespeicherte)"""
        return {
            'first_name': self.first_name_input.text(),
            'last_name': self.last_name_input.text(),
            'birth_date': self.birth_date_input.text(),
            'matriculation_no': self.matriculation_no_input.text()
        }
    
    def clear_form(self):
        """Formular zurücksetzen nach erfolgreichem Speichern"""
        self.first_name_input.clear()
        self.last_name_input.clear()
        self.birth_date_input.clear()
        self.matriculation_no_input.clear()