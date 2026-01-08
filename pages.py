''' OFFENE TODOS IM FILE ABARBEITEN!!!

ALLGEMEINE TODOS:
[] Kommentare aufräumen + Docstring ergänzen
[x] Dropdown Menüs aus der DB
[x] Dropdown Menüs aus Backend-Liste 
[x] MotherClass einführen
[x] load_students und load_exams in GradePage reimplementieren
[x] delete_btn in allen Pages implementieren (zuerst StudentPage)
[x] Worker implementieren 
[x] Settings 
[x] .emit zeiten anpassen 
[] Alter bei Studenten prüfen
[] Fehlermöglichkeiten prüfen 
[] load_last_matriculation_number implementieren
[] requirements.txt 
[x] Form Layouts kicken
[x] shiny in stats page implementieren

MIT MARVIN ABSTIMMEN:
[x] wie wird die MatrikelNr. eingeführt/validiert?


'''
from database_worker import DatabaseWorker
from Data_Base_Connection import prepare_database
import json
import os 
from PySide6.QtCore import Signal, QDate, Qt, QProcess, QUrl
from PySide6.QtGui import QDoubleValidator, QIntValidator, QPixmap
from PySide6.QtWidgets import QComboBox, QDateEdit, QHBoxLayout, QWidget, QVBoxLayout, QLabel, QLineEdit, QPushButton, QFormLayout
from PySide6.QtWebEngineWidgets import QWebEngineView
import signal
import subprocess
import time

MSG_TIME = 3000

ERR_MSG_TIME = 5000

def dropdown_options_path():
    """loads the dropdown_options.json path and returns it"""
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
    """ This is a BaseClass to implement methods and designs which are shared by unique SubClasses"""
    
    # Signals to send information to the MainWindow
    data_changed = Signal(dict)
    status_message = Signal(str, int)
    
    
    def __init__(self, title):
        """
        Args:
            title: the title displayed on page SubClass
        """
        super().__init__()
        self.base_path = os.path.dirname(os.path.abspath(__file__)) 
        self.image_path = os.path.join(self.base_path, "Images")
        self.data = {}  
        self.title = title
        self.setup_base_ui()


    def setup_base_ui(self):
        """Setup base ui similar for every page"""
        self.main_layout = QVBoxLayout()
        
        # Headline
        header = self.create_header(self.title)
        self.main_layout.addLayout(header)
        
        # Separator (Design-Element)
        self.main_layout.addWidget(self.create_separator())
        self.main_layout.addSpacing(10)
        
        # Content-Area (will be filled by subclasses)
        self.content_layout = QVBoxLayout()
        self.main_layout.addLayout(self.content_layout)
        
        self.setLayout(self.main_layout)
    
    def create_header(self, title):
        """Create Header with Title and Aalen-University Logo"""
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
    
    def create_info_label(self, label_text):
        self.info_btn = QPushButton("(i) Show help")
        self.info_btn.setStyleSheet("text-align: left; border: none; color: #0073B9;")
        self.info_btn.clicked.connect(self.toggle_info)

        self.info_label=QLabel(label_text)
        self.info_label.setWordWrap(True)
        self.info_label.setStyleSheet(
            "background-color: #f0f8ff; padding: 10px; border-radius: 5px; "
            "color: #333; font-size: 12px; margin: 5px 0;"
        )
        self.info_label.setVisible(False) 
        
        self.content_layout.addWidget(self.info_btn)
        self.content_layout.addWidget(self.info_label)

    def toggle_info(self):
        """Toggle info label visibility"""
        is_visible = self.info_label.isVisible()
        self.info_label.setVisible(not is_visible)
        self.info_btn.setText("(i) Hide help" if not is_visible else "(i) Show help")

    def setup_ui(self):
        """Has to be implemented by SubClass"""
        raise NotImplementedError("Unterklassen müssen setup_ui() implementieren")
    
    def save_data(self):
        """Has to be implemented by SubClass"""
        raise NotImplementedError("Unterklassen müssen save_data() implementieren")
    
    def get_data(self):
        """Has to be implemented by SubClass"""
        raise NotImplementedError("Unterklassen müssen get_data() implementieren")
    
    def clear_form(self):
        """Has to be implemented by SubClass"""
        raise NotImplementedError("Unterklassen müssen clear_form() implementieren")

    def create_separator(self):
        """Create separator as Design-Element for SubClasses"""
        separator = QLabel()
        separator.setStyleSheet("QLabel { border-bottom: 1px solid #bdc3c7; margin: 15px 0; }")
        separator.setFixedHeight(3)
        return separator
    
    def create_section_label(self, label=str):
        """
        Create section header/label for SubClasses
        Args:
            label: headline used on page for this section
        """
        section_label = QLabel(label)
        section_label.setStyleSheet("font-size: 16px; font-weight: bold; margin-top: 10px;")
        return section_label

    # === Shared Database Loading Methods ===

    def load_students_into_dropdown(self, combobox: QComboBox, placeholder: str = "-- Select student --"):
        """
        Load students from database into a combobox

        Args:
            combobox: The QComboBox to populate
            placeholder: Item default at [0]
        """

        query = """SELECT matriculation_number, first_name, last_name 
                   FROM student ORDER BY last_name, first_name"""
        
        student_worker = DatabaseWorker(query, fetch = True)

        student_worker.data_fetched.connect(
            lambda success, rows, error_msg, cb = combobox, ph = placeholder: self._on_students_loaded(success, rows, error_msg, cb, ph))
        
        if not hasattr(self, '_active_workers'):
            self._active_workers = []
        self._active_workers.append(student_worker)

        student_worker.operation_finished.connect(lambda: self._cleanup_worker(student_worker))
        student_worker.start()




    def _on_students_loaded(self, success, rows, error_msg, combobox, placeholder):
        """
        Callback when students are loaded by the worker
        Args:   
            success: boolean if loading succeeded 
            rows: list of data 
            error_msg: error msg to display as status_message
        """
        if not success: 
            self.status_message.emit(f"Error loading students: {error_msg}", ERR_MSG_TIME)
            return

        combobox.clear()
        combobox.addItem(placeholder, None)

        for row in rows: 
            matriculation_number, first_name, last_name = row
            display_text = f"{last_name}, {first_name} ({matriculation_number})"
            combobox.addItem(display_text, matriculation_number)

    def load_exams_into_dropdown(self, combobox: QComboBox, placeholder: str = "-- Select exam --"):
        """
        Load exams from database into a combobox.
        
        Args:
            combobox: The QComboBox to populate
            placeholder: First item text (default: "-- Select exam --")
        """

        query = "SELECT pnr, title, semester, exam_date FROM exam ORDER BY title"

        exam_worker = DatabaseWorker(query, fetch = True)
        exam_worker.data_fetched.connect(
            lambda success, rows, error_msg, cb=combobox, ph=placeholder: self._on_exams_loaded(success, rows, error_msg, cb, ph))
        
        if not hasattr(self, '_active_workers'):
            self._active_workers = []
        self._active_workers.append(exam_worker)

        exam_worker.operation_finished.connect(lambda: self._cleanup_worker(exam_worker))
        exam_worker.start()

    def _on_exams_loaded(self, success, rows, error_msg, combobox, placeholder):
        """
        Callback when exams are loaded
        Args:   
            success: boolean if loading succeeded 
            rows: list of data 
            error_msg: error msg to display as status_message
        """
        if not success:
            self.status_message.emit(f"Error loading exams: {error_msg}", ERR_MSG_TIME)
            return
        
        combobox.clear()
        combobox.addItem(placeholder, None)

        for row in rows:
            pnr, title, semester, exam_date = row
            display_text = f"{pnr} - {title} ({exam_date} | {semester})"
            combobox.addItem(display_text, pnr)

    def _cleanup_worker(self, worker):
        """Remove finished workers from the _active_worker list."""
        if hasattr(self, '_active_workers') and worker in self._active_workers:
            self._active_workers.remove(worker)

    def delete_record(self, table: str, id_column: str, id_value, callback=None, id_column2:str =None, id_value2=None):
        """
        Delete a record from the database.
        
        Args:
            table: Table name (e.g., "student", "exam", "grade")
            id_column: Column name for the ID (e.g., "matriculation_number", "pnr")
            id_value: The value to delete
            callback: Optional callback function(success, message)
            id_column2: Second column name for grade table (pnr)
            id_value2: Second value (only for grade table)
        """
        if id_value is None:
            self.status_message.emit("Please select an item to delete", MSG_TIME)
            return

        if table == "grade": 
            # needs 2 informations: which student (mat. number) and which exam (pnr)
            query = f"DELETE FROM {table} WHERE {id_column} = %s and {id_column2} = %s"
            params = (id_value, id_value2)

        elif table == "exam":
            query = f"DELETE FROM {table} WHERE {id_column} = %s"
            params = (id_value,)
        
        elif table == "student":
            query = f"DELETE FROM {table} WHERE {id_column} = %s"
            params = (id_value,)

        else:
            self.status_message.emit(f"Error: could not delete from table {table}.")
            return


        self._delete_callback = callback
        self.delete_worker = DatabaseWorker(query, params)
        self.delete_worker.operation_finished.connect(self._on_delete_finished)
        self.delete_worker.start()
        
        self.status_message.emit("Deleting...", 0) # das ist doch quatsch 

    def _on_delete_finished(self, success, message, rows_affected):
        """
        Callback when delete operation finishes
        Args:   
            success: boolean if loading succeeded 
            rows: list of data 
            message: message to display as status_message
        """
        if success and rows_affected > 0:
            self.status_message.emit("Record deleted successfully!", MSG_TIME)
        elif success and rows_affected == 0:
            self.status_message.emit("Error: There was no record to delete with given specification", ERR_MSG_TIME)
        else:
            self.status_message.emit(f"Error deleting: {message}", ERR_MSG_TIME)
        
        if self._delete_callback:
            self._delete_callback(success, message, rows_affected)

class HomePage(BasePage):
    """
    HomePage - containing database Settings and option to add new semesters and study programs
    """
    def __init__(self):
        super().__init__("Home Page & Settings")
        self.setup_ui()
        self.load_current_config()

    def setup_ui(self):
        # === Database Connection Section ===
        creation_section_label = self.create_section_label("Database Connection")
        self.content_layout.addWidget(creation_section_label)

        # Info-Box 

        label_info = "You should not have to change Host, Port and Database. "\
            "Your Username is either your PostgreSQL username or your login username of your device. "\
            "Your Password is either your PostgreSQL password or blank."

        self.create_info_label(label_info)
        
        # Database settings
        host_layout = QHBoxLayout()
        port_layout = QHBoxLayout()
        database_layout = QHBoxLayout()
        username_layout = QHBoxLayout()
        password_layout = QHBoxLayout()
        min_label_width = 210

        self.host_label = QLabel("Host:")
        self.host_label.setMinimumWidth(min_label_width)
        self.host_input = QLineEdit()
        self.host_input.setPlaceholderText("Default: localhost")
        host_layout.addWidget(self.host_label)
        host_layout.addWidget(self.host_input)
        
        self.port_label = QLabel("Port:")
        self.port_label.setMinimumWidth(min_label_width)
        self.port_input = QLineEdit()
        self.port_input.setPlaceholderText("Default: 5432")
        port_validator = QIntValidator(1, 65535)
        self.port_input.setValidator(port_validator)
        port_layout.addWidget(self.port_label)
        port_layout.addWidget(self.port_input)

        self.database_label = QLabel("Database:")
        self.database_label.setMinimumWidth(min_label_width)
        self.database_input = QLineEdit()
        self.database_input.setPlaceholderText("Default: db_exam_management")
        database_layout.addWidget(self.database_label)
        database_layout.addWidget(self.database_input)

        self.username_label = QLabel("Username")
        self.username_label.setMinimumWidth(min_label_width)
        self.username_input = QLineEdit()
        self.username_input.setPlaceholderText("Your PostgreSQL username")
        username_layout.addWidget(self.username_label)
        username_layout.addWidget(self.username_input)

        self.password_label = QLabel("Password:")
        self.password_label.setMinimumWidth(min_label_width)
        self.password_input = QLineEdit()
        self.password_input.setPlaceholderText("Your PostgreSQL password")
        self.password_input.setEchoMode(QLineEdit.EchoMode.Password)
        password_layout.addWidget(self.password_label)
        password_layout.addWidget(self.password_input)

        self.content_layout.addLayout(host_layout)
        self.content_layout.addLayout(port_layout)
        self.content_layout.addLayout(database_layout)
        self.content_layout.addLayout(username_layout)
        self.content_layout.addLayout(password_layout)


        # DB-Config Buttons
        db_btn_layout = QHBoxLayout()
        self.save_config_btn = QPushButton("Save Connection")
        self.save_config_btn.clicked.connect(self.save_login_config)
        self.test_connection_btn = QPushButton("Test Connection")
        self.test_connection_btn.clicked.connect(self.test_connection)
        self.restore_default_btn = QPushButton("restore defaults")
        self.restore_default_btn.clicked.connect(self.restore_default_conn)
        db_btn_layout.addWidget(self.save_config_btn)
        db_btn_layout.addWidget(self.test_connection_btn)
        db_btn_layout.addWidget(self.restore_default_btn)
        self.content_layout.addLayout(db_btn_layout)
        self.content_layout.addWidget(self.create_separator())


        # === Dropdown Options Section ===
        dropdown_section_label = self.create_section_label("Dropdown options")
        self.content_layout.addWidget(dropdown_section_label)

        self.semester_layout = QHBoxLayout()
        self.study_program_layout = QHBoxLayout()
        
        self.new_semester_label = QLabel("Add new semester:")
        self.new_semester_label.setMinimumWidth(min_label_width)
        self.new_semester_input = QLineEdit()
        self.new_semester_input.setPlaceholderText("e.g. SoSe 26 or WiSe 26/27")
        self.add_semester_btn = QPushButton("Add")
        self.add_semester_btn.clicked.connect(self.add_semester_btn_clicked)

        self.new_study_program_label = QLabel("Add new study / degree program:")
        self.new_study_program_label.setMinimumWidth(min_label_width)
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
        """Loads current config values into the database-settings fields"""
        success, config, error_msg = load_login_config()
        if success:
            self.host_input.setText(config.get("host", "localhost"))
            self.port_input.setText(str(config.get("port", 5432)))
            self.database_input.setText(config.get("database", ""))
            self.username_input.setText(config.get("username", ""))
            self.password_input.setText(config.get("password", ""))
        else:
            self.status_message.emit(f"Error loading config: {error_msg}", ERR_MSG_TIME)

    def save_login_config(self):
        """Saves the login config to the JSON file"""
        if not self.username_input.text().strip():
            self.status_message.emit("Please enter a username", MSG_TIME)
            return
        
        if not self.host_input.text().strip():
            self.status_message.emit("Please enter a host", MSG_TIME)
            return

        if not self.port_input.text().strip():
            self.status_message.emit("Please enter a port", MSG_TIME)
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
            self.status_message.emit("Database configuration saved successfully!", MSG_TIME)
        except Exception as e:
            self.status_message.emit(f"Error saving config: {e}", ERR_MSG_TIME)

        prepare_database()

    def test_connection(self):
        """Tests the database connection with current settings"""
        try:
            import psycopg2
            conn = psycopg2.connect(
                host=self.host_input.text(),
                port=int(self.port_input.text()),
                database=self.database_input.text(),
                user=self.username_input.text(),
                password=self.password_input.text()
            )
            conn.close()
            self.status_message.emit("Connection successful!", MSG_TIME)
        except Exception as e:
            self.status_message.emit(f"Connection failed: {e}", ERR_MSG_TIME)

    def restore_default_conn(self):
        """restores the default values for Host, Port and Database"""
        self.host_input.setText("localhost")
        self.port_input.setText("5432")
        self.database_input.setText("db_exam_management")
        self.status_message.emit("Default values restored", MSG_TIME)

    def add_semester_btn_clicked(self):
        key = "semesters"
        value = self.new_semester_input.text()

        if not value:
            self.status_message.emit("Please enter a semester", MSG_TIME)
            return

        success = self.append_dropdown_options(key, value)
        if success:
            self.new_semester_input.clear()
            self.status_message.emit(f"Added {value} to Semesters", MSG_TIME)

    def add_study_program_btn_clicked(self):
        key = "study_programs"
        value = self.new_study_program_input.text()

        if not value:
            self.status_message.emit("Please enter a study program", MSG_TIME)
            return

        success = self.append_dropdown_options(key, value)
        if success: 
            self.new_study_program_input.clear()
            self.status_message.emit(f"Added {value} to study programs", MSG_TIME)

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
                self.status_message.emit(f"Error: cannot append to list {key}", ERR_MSG_TIME)
                return False
            
            if value in data[key]:
                self.status_message.emit(f"'{value}' already exists in {key}", MSG_TIME)
                return False
            
            data[key].append(value)
            return self.save_dropdown_json(data)
        else: 
            self.status_message.emit(f"Error: {error_msg}", ERR_MSG_TIME)
            return False

    def save_dropdown_json(self, data: dict):
        """Saves appended dropdown_options.json file"""
        config_path = dropdown_options_path()
        try:
            with open(config_path, 'w', encoding='utf-8') as file:
                json.dump(data, file, indent=4, ensure_ascii=False)
                return True
        except Exception as e:
                self.status_message.emit(f"Error while saving Data to the list: {e}", ERR_MSG_TIME)
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
        self.load_students_into_dropdown(self.student_input)
        self.load_exams_into_dropdown(self.exam_input)
        self.load_students_into_dropdown(self.delete_grade_student_input)
        self.load_exams_into_dropdown(self.delete_grade_exam_input)

    def setup_ui(self):
        # === Create Section ===
        creation_section_label = self.create_section_label("Create grades for students")
        self.content_layout.addWidget(creation_section_label)
        form_layout = QFormLayout()
        
        label_info = "To grade a student, please select a student, an exam and enter a grade. " \
        "Click Save to save it to the database. Every student can only have one grade for one exam. " \
        "Grades range from 1.0 to 6.0. If you want to delete a grade, please select student and exam " \
        "in the delete menu below and click delete. Refresh the page by clicking onto another page & return."

        self.create_info_label(label_info)

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
    
    # === Delete Section ===
        deletion_section_label = self.create_section_label("Delete grades for students")
        self.content_layout.addWidget(deletion_section_label)
        self.delete_grade_student_label = QLabel("Select student to delete their grade:")
        self.delete_grade_student_input = QComboBox()
        self.delete_grade_exam_label = QLabel("Select exam to delete the grade:")
        self.delete_grade_exam_input = QComboBox()
        self.delete_btn = QPushButton("Delete")
        self.delete_btn.clicked.connect(self.delete_grade)

        self.content_layout.addWidget(self.create_separator())
        self.content_layout.addWidget(self.delete_grade_student_label)
        self.content_layout.addWidget(self.delete_grade_student_input)
        self.content_layout.addWidget(self.delete_grade_exam_label)
        self.content_layout.addWidget(self.delete_grade_exam_input)
        self.content_layout.addWidget(self.delete_btn)
        self.content_layout.addStretch()  

    def delete_grade(self):
        """ delete grade for selected student and exam"""
        self.mat_no_del = self.delete_grade_student_input.currentData() # matriculation number of student to delete their grade
        self.exam_no_del = self.delete_grade_exam_input.currentData() #pnr of exam to delete grade 
        if self.mat_no_del is None:
            self.status_message.emit("Please select a student to delete their grade", MSG_TIME)
            return
        elif self.exam_no_del is None:
            self.status_message.emit("Please select an exam to delete a grade", MSG_TIME)
            return
        else:
            self.delete_record("grade", "matriculation_number", self.mat_no_del, self.on_deleted, "pnr", self.exam_no_del)

    def on_deleted(self, success, message, rows_affected):
        if success and rows_affected > 0:
            self.reload_dropdowns()
            self.status_message.emit(f"grade for student with mat. no. {self.mat_no_del} for exam with pnr {self.exam_no_del} deleted successfully", MSG_TIME)
        elif success and rows_affected == 0:
            self.reload_dropdowns()
            self.status_message.emit("the selected student does not have a grade for the selected exam!", MSG_TIME)
            return
        else:
            self.status_message.emit(f"{message}")

    def save_data(self):
        if  self.student_input.currentIndex() == 0:
            self.status_message.emit("Please select a student", MSG_TIME)
            return
        if  self.exam_input.currentIndex() == 0:
            self.status_message.emit("Please select an exam", MSG_TIME)
            return
        if not self.grade_input.text().strip():
            self.status_message.emit(f"Please enter a grade", MSG_TIME)
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
        self.db_worker.operation_finished.connect(self.on_save_finished)
        self.db_worker.start()

        self.data = {
            'student': self.student_input.currentText(),
            'exam': self.exam_input.currentText(),
            'grade': self.grade_input.text()
        }
        
        self.data_changed.emit(self.data)
    
    def on_save_finished(self, success, message):
        if success: 
            self.status_message.emit(message, MSG_TIME)
            self.data = self.get_data()
            self.data_changed.emit(self.data)
            self.clear_form()

        else:
            if "grade_unique_student_exam" in message or "unique" in message.lower():
                self.status_message.emit("This student already has a grade for this exam! Delete the grade first to update it!", MSG_TIME) 
            else:
                self.status_message.emit(f"Error: {message}", ERR_MSG_TIME)          




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
        self.reload_student_dropdown()

    def showEvent(self, event):
        """Gets called when switching to this tab/page"""
        super().showEvent(event)
        self.reload_student_dropdown()

    def reload_student_dropdown(self):
        """reload the delete dropdown-list from the db"""
        self.load_students_into_dropdown(self.delete_student_input, "-- Select student to delete --")

    def setup_ui(self):
        # === Create Section ===
        creation_section_label = self.create_section_label("Create students")
        self.content_layout.addWidget(creation_section_label)
        form_layout = QFormLayout()
        
        label_info = "To create a student, please enter a name, firstname birthdate and a matriculation number and click save. " \
        "The matriculation number has to be unique, between 0 and 999999999. The age of the student has to be between 5 and 120 years. " \
        "If you want to delete a student, please select the student in the delete menu below and click delete. Refresh the page by clicking onto another page & return."

        self.create_info_label(label_info)

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
        #TODO: Berechnung alter & validator. -> berücksichtigung in infolabel
        form_layout.addRow("Matriculation Number:", self.matriculation_no_input)

        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.save_data)
        
        self.content_layout.addLayout(form_layout)
        self.content_layout.addWidget(save_btn)


        # === Delete Section ===
        deletion_section_label = self.create_section_label("Delete students")
        self.content_layout.addWidget(deletion_section_label)

        self.delete_student_label = QLabel("Select student to delete:")
        self.delete_student_input = QComboBox()
        self.delete_btn = QPushButton("Delete")
        self.delete_btn.clicked.connect(self.delete_student)

        self.content_layout.addWidget(self.create_separator())
        self.content_layout.addWidget(self.delete_student_label)
        self.content_layout.addWidget(self.delete_student_input)
        self.content_layout.addWidget(self.delete_btn)
        self.content_layout.addStretch()

    def delete_student(self):
        """Delete selected student"""
        self.matriculation_number_del = self.delete_student_input.currentData()

        if self.matriculation_number_del is None:
            self.status_message.emit("Please select a student to delete", MSG_TIME)
            return
        
        else:
            self.delete_record("student", "matriculation_number", self.matriculation_number_del, self.on_deleted)

    def on_deleted(self, success, message, rows_affected):
        if success:
            self.reload_student_dropdown()
            self.status_message.emit(f"student with mat. no {self.matriculation_number_del} deleted successfully", MSG_TIME)
        else:
            self.status_message.emit(f"{message}")

    def save_data(self):
        if not self.first_name_input.text().strip():
            self.status_message.emit("Please enter a firstname", MSG_TIME)
            return
        if not self.last_name_input.text().strip():
            self.status_message.emit("Please enter a lastname", MSG_TIME)
            return
        if not self.matriculation_no_input.text().strip():
            self.status_message.emit("Please enter a matriculation number", MSG_TIME)
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
        self.db_worker.operation_finished.connect(self.on_save_finished) 
        self.db_worker.start()
        
        self.status_message.emit("Saving...", 0)# TODO: das ist doch quatsch
    
    def on_save_finished(self, success, message):
        if success:
            self.status_message.emit(message, MSG_TIME)
            self.data = self.get_data()
            self.data_changed.emit(self.data)
            self.clear_form()
            self.reload_student_dropdown()
        else:
            self.status_message.emit(message, ERR_MSG_TIME)
        
    
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
        self.reload_json_dropdowns()

    def showEvent(self, event):
        """ gets called when switching to this tab/page"""
        super().showEvent(event)
        self.reload_json_dropdowns()
        self.reload_exam_dropdown()

    def reload_json_dropdowns(self):
        """reloads dropdown options from the JSON-file"""
        success, options, error_msg = load_dropdown_options()

        if not success:
            self.status_message.emit(f"Error: {error_msg}", ERR_MSG_TIME)
            return

        self.semester_input.clear()
        self.semester_input.addItem("-- Select semester --")
        self.semester_input.addItems(options.get("semesters", []))

        self.study_program_input.clear()
        self.study_program_input.addItem("--Select study program --")
        self.study_program_input.addItems(options.get("study_programs", []))

    def reload_exam_dropdown(self):
        """reload the delete dropdown-list from the db"""
        self.load_exams_into_dropdown(self.delete_exam_input, "-- Select exam to delete --")

    def setup_ui(self):
        # === Create Section === 
        creation_section_label = self.create_section_label("Create exam")
        self.content_layout.addWidget(creation_section_label)
        form_layout = QFormLayout()
              
        label_info = "To create an exam, please enter a PNr, a title, a date and select a semester and a study program " \
        "Click Save to save it to the database. Every student can only have one grade for one exam. " \
        "Grades range from 1.0 to 6.0. The date of an exam can be in the past as well as in the future! " \
        "If you want to delete a grade, please select student and exam in the delete menu below and click delete. " \
        "Refresh the page by clicking onto another page & return."

        self.create_info_label(label_info)  
        
        self.pnr_input = QLineEdit()
        self.pnr_input.setPlaceholderText("Exam number")

        self.exam_title_input = QLineEdit()
        self.exam_title_input.setPlaceholderText("Exam title")

        self.exam_date_input = QDateEdit()
        self.exam_date_input.setDisplayFormat("dd.MM.yyyy")
        self.exam_date_input.setCalendarPopup(True)

        self.semester_input = QComboBox()
        self.study_program_input = QComboBox()


        form_layout.addRow("PNr:", self.pnr_input)
        form_layout.addRow("Title:", self.exam_title_input)
        form_layout.addRow("Date:", self.exam_date_input)
        form_layout.addRow("Semester:", self.semester_input)
        form_layout.addRow("Study program:", self.study_program_input)
        
        
        save_btn = QPushButton("Save")
        save_btn.clicked.connect(self.save_data)

        self.content_layout.addLayout(form_layout)
        self.content_layout.addWidget(save_btn)

        # === Delete Section ===
        deletion_section_label = self.create_section_label("Delete exam")
        self.content_layout.addWidget(deletion_section_label)

        self.delete_exam_label = QLabel("Select exam to delete:")
        self.delete_exam_input = QComboBox()
        self.delete_btn = QPushButton("Delete")
        self.delete_btn.clicked.connect(self.delete_exam)

        self.content_layout.addWidget(self.create_separator())
        self.content_layout.addWidget(self.delete_exam_label)
        self.content_layout.addWidget(self.delete_exam_input)
        self.content_layout.addWidget(self.delete_btn)
        self.content_layout.addStretch()

    def delete_exam(self):
        """ delete selected exam"""
        self.pnr_del = self.delete_exam_input.currentData()

        if self.pnr_del is None:
            self.status_message.emit("Please select an exam to delete", MSG_TIME)
            return

        else: 
            self.delete_record("exam", "pnr", self.pnr_del, self.on_deleted)

    def on_deleted(self, success, message, rows_affected):
        if success:
            self.reload_exam_dropdown()
            self.status_message.emit(f"exam with pnr {self.pnr_del} deleted successfully", MSG_TIME)
        else:
            self.status_message.emit(f"{message}")



    def save_data(self):
        if not self.pnr_input.text().strip():
            self.status_message.emit("Please enter an exam number", MSG_TIME)
            return
        if not self.exam_title_input.text().strip():
            self.status_message.emit("Please enter an exam title", MSG_TIME)
            return
        if not self.exam_date_input.text().strip():
            self.status_message.emit("Please enter an exam date", MSG_TIME)
            return
        if self.semester_input.currentIndex() == 0:
            self.status_message.emit("Please select a semester", MSG_TIME) 
            return
        if self.study_program_input.currentIndex() == 0: 
            self.status_message.emit("Please select a study program", MSG_TIME) 
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
        self.db_worker.operation_finished.connect(self.on_save_finished)
        self.db_worker.start()
        
        self.status_message.emit("Saving...", 0)
    
    def on_save_finished(self, success, message):
        if success:
            self.status_message.emit(message, MSG_TIME)
            self.data = self.get_data()
            self.data_changed.emit(self.data)
            self.clear_form()
            self.reload_exam_dropdown()
        else:
            self.status_message.emit(message, ERR_MSG_TIME)


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
            self.status_message.emit("Please enter an exam number (\"PNr\") to delete it", MSG_TIME) 
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
        self.shiny_process = None
        self.shiny_port = 8050
        self.setup_ui()

    def setup_ui(self):
        """ setup UI with start & stop buttons"""

        label_info = "To start the dashboard, click 'start dashboard'. "\
        "You can resize the window, the dashboard should adapt. "\
        "You can visit <a href='http://localhost:8050'>http://localhost:8050</a> in your browser, to show the dashboard in there. "\
        "This will only work, if you've successfully started the dashboard via the 'start dashboard' button."

        self.create_info_label(label_info)
        self.info_label.setOpenExternalLinks(True)

        btn_layout = QHBoxLayout()
        self.start_btn = QPushButton("Start Dashboard")
        self.start_btn.clicked.connect(self.start_shiny_app)
        self.stop_btn = QPushButton("Stop Dashboard") 
        self.stop_btn.clicked.connect(self.stop_shiny_app)
        self.stop_btn.setEnabled(False)
        
        btn_layout.addWidget(self.start_btn)
        btn_layout.addWidget(self.stop_btn)
        self.content_layout.addLayout(btn_layout)
        
        
        self.web_view = QWebEngineView()
        self.content_layout.addWidget(self.web_view,1)
        
    def start_shiny_app(self):
        """Start the R Shiny Server in the background if it's not already running"""
        if self.shiny_process is not None:
            return 
        shiny_script_path = os.path.join(self.base_path, "shiny_dashboard/app.R")

        if not os.path.exists(shiny_script_path):
            self.status_message.emit(f"Shiny app not found at: {shiny_script_path}", ERR_MSG_TIME)
            return
        try: 
            self.shiny_process = subprocess.Popen(
                ['Rscript', '-e', f'shiny::runApp("{shiny_script_path}", port={self.shiny_port}, launch.browser=FALSE)'],
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
                stdin=subprocess.DEVNULL,
                start_new_session=True
            )

            time.sleep(2)

            self.web_view.setUrl(QUrl(f"http://localhost:{self.shiny_port}"))
            self.stop_btn.setEnabled(True)
            self.status_message.emit("Shiny Dashboard startet successfully!", MSG_TIME)

        except Exception as e: 
            self.status_message.emit(f"Error starting Shiny: {e}", ERR_MSG_TIME)

    def stop_shiny_app(self):
        """Stop the Shiny server and kill all child processes"""
        if self.shiny_process:
            try:

                os.killpg(os.getpgid(self.shiny_process.pid), signal.SIGTERM)
                self.shiny_process.wait(timeout=3)
            except ProcessLookupError:
                pass 
            except subprocess.TimeoutExpired:
                # Force kill if SIGTERM didn't work
                try:
                    os.killpg(os.getpgid(self.shiny_process.pid), signal.SIGKILL)
                except ProcessLookupError:
                    pass
            finally:
                self.shiny_process = None

            self.web_view.setUrl(QUrl("about:blank"))
            self.start_btn.setEnabled(True)
            self.stop_btn.setEnabled(False)
            self.status_message.emit("Shiny Dashboard stopped", MSG_TIME)



    def save_data(self):
        pass
    
    def get_data(self):
        pass
    
    def clear_form(self):
        pass
