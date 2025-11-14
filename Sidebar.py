import os
from pages import GradePage 
from PySide6.QtCore import QSize, Qt, QDate, Signal, Slot
from PySide6.QtGui import QIcon, QPixmap
from PySide6.QtWidgets import (QMainWindow, QPushButton, QStatusBar, QLineEdit, QComboBox,
QHBoxLayout, QVBoxLayout, QWidget, QLabel, QTabWidget, QDateEdit, 
)


class MainWindow(QMainWindow):

    # setup the main window, the relative image path, the GUI widgets and the main-window-layout
    def __init__(self, app):
        super().__init__()
        self.app = app
        self.base_path = os.path.dirname(os.path.abspath(__file__)) 
        self.image_path = os.path.join(self.base_path, "Images")
        self.setup_window()

    #TODO: Datenbankverbindung herstellen

    # setup the frame of the main window 
    def setup_window(self):
        self.setWindowTitle("ExaMS")
        self.setFixedSize(800, 600) # maybe change this to resizable later
        self.setStatusBar(QStatusBar(self))
        self.create_sidebar_buttons()
        self.setup_tabs()
        self.setup_layout()


    # setup sidebar-buttons, apply style and connect to functions
    def create_sidebar_buttons(self):

        # home button
        self.home_btn = QPushButton()
        self.home_btn.setIcon(QIcon(os.path.join(self.image_path, "home.png")))
        self.home_btn_icon_normal = QIcon(os.path.join(self.image_path, "home.png"))
        self.home_btn_icon_active = QIcon(os.path.join(self.image_path, "home_active.png"))
        self.apply_sidebar_button_style(self.home_btn)
        self.home_btn.clicked.connect(self.home_btn_clicked)       

        # grade entry
        self.grade_entry_btn = QPushButton()
        self.grade_entry_btn.setIcon(QIcon(os.path.join(self.image_path, "grade.png")))
        self.grade_entry_btn_icon_normal = QIcon(os.path.join(self.image_path, "grade.png"))
        self.grade_entry_btn_icon_active = QIcon(os.path.join(self.image_path, "grade_active.png"))
        self.apply_sidebar_button_style(self.grade_entry_btn)
        self.grade_entry_btn.clicked.connect(self.grade_entry_btn_clicked)
    
        # student entry 
        self.student_entry_btn = QPushButton()
        self.student_entry_btn.setIcon(QIcon(os.path.join(self.image_path, "student.png")))
        self.student_entry_btn_icon_normal = QIcon(os.path.join(self.image_path, "student.png"))
        self.student_entry_btn_icon_active = QIcon(os.path.join(self.image_path, "student_active.png"))
        self.apply_sidebar_button_style(self.student_entry_btn)
        self.student_entry_btn.clicked.connect(self.student_entry_btn_clicked)

        # exam entry
        self.exam_entry_btn = QPushButton()
        self.exam_entry_btn.setIcon(QIcon(os.path.join(self.image_path, "exam.png")))
        self.exam_entry_btn_icon_normal = QIcon(os.path.join(self.image_path, "exam.png"))
        self.exam_entry_btn_icon_active = QIcon(os.path.join(self.image_path, "exam_active.png"))
        self.apply_sidebar_button_style(self.exam_entry_btn)
        self.exam_entry_btn.clicked.connect(self.exam_entry_btn_clicked)


        # stats button
        self.stats_btn = QPushButton()
        self.stats_btn.setIcon(QIcon(os.path.join(self.image_path, "stats.png")))
        self.stats_btn_icon_normal = QIcon(os.path.join(self.image_path, "stats.png"))
        self.stats_btn_icon_active = QIcon(os.path.join(self.image_path, "stats_active.png"))
        self.apply_sidebar_button_style(self.stats_btn)
        self.stats_btn.clicked.connect(self.stats_btn_clicked)

    def update_button_icons(self):
            self.home_btn.setIcon(self.home_btn_icon_active if self.home_btn.isChecked() else self.home_btn_icon_normal)
            self.grade_entry_btn.setIcon(self.grade_entry_btn_icon_active if self.grade_entry_btn.isChecked() else self.grade_entry_btn_icon_normal)
            self.student_entry_btn.setIcon(self.student_entry_btn_icon_active if self.student_entry_btn.isChecked() else self.student_entry_btn_icon_normal)
            self.exam_entry_btn.setIcon(self.exam_entry_btn_icon_active if self.exam_entry_btn.isChecked() else self.exam_entry_btn_icon_normal)
            self.stats_btn.setIcon(self.stats_btn_icon_active if self.stats_btn.isChecked() else self.stats_btn_icon_normal)

    '''Tab-Management'''
    def setup_tabs(self):
        self.home_tab = self.home_page()
        self.grade_tab = GradePage()
        self.student_tab = self.student_page()
        self.exam_tab = self.exam_page()
        self.stats_tab = self.stats_page()
        



    # TODO: Style auf Sidebar buttons anpassen
    def apply_sidebar_button_style(self, button):
        button.setCheckable(True)
        button.setChecked(False)
        button.setFixedSize(QSize(100, 100))
        button.setIconSize(QSize(100, 100))  # Icon füllt den gesamten Button
        button.setStyleSheet("""
            QPushButton {
                padding: 0px;
                border: 2px solid #cccccc;
                border-radius: 5px;
                background-color: transparent;
            }
            QPushButton:hover {
                border: 2px solid #3daee9;
                background-color: transparent;
            }
            QPushButton:pressed {
                border: 3px solid #2980b9;
                background-color: transparent;
            }
            QPushButton:checked {
                border: 3px solid #27ae60;
                background-color: transparent;
            }
        """)


    def home_btn_clicked(self):
        self.uncheck_sidebar_buttons()
        self.home_btn.setChecked(True)
        self.update_button_icons()
        self.right_widget.setCurrentIndex(0)

    def grade_entry_btn_clicked(self):
        self.uncheck_sidebar_buttons()
        self.grade_entry_btn.setChecked(True)
        self.update_button_icons()
        self.right_widget.setCurrentIndex(1)

    def student_entry_btn_clicked(self):
        self.uncheck_sidebar_buttons()
        self.student_entry_btn.setChecked(True)
        self.update_button_icons()
        self.right_widget.setCurrentIndex(2)

    def exam_entry_btn_clicked(self):
        self.uncheck_sidebar_buttons()
        self.exam_entry_btn.setChecked(True)
        self.update_button_icons()
        self.right_widget.setCurrentIndex(3)

    def stats_btn_clicked(self):
        self.uncheck_sidebar_buttons()
        self.stats_btn.setChecked(True)
        self.update_button_icons()
        self.right_widget.setCurrentIndex(4)



    def uncheck_sidebar_buttons(self):
        self.home_btn.setChecked(False)
        self.grade_entry_btn.setChecked(False)
        self.student_entry_btn.setChecked(False)
        self.exam_entry_btn.setChecked(False)
        self.stats_btn.setChecked(False)


    def setup_layout(self):
        left_layout = QVBoxLayout()
        left_layout.addWidget(self.home_btn)
        left_layout.addWidget(self.grade_entry_btn)
        left_layout.addWidget(self.student_entry_btn)
        left_layout.addWidget(self.exam_entry_btn)
        left_layout.addWidget(self.stats_btn)
        left_layout.addStretch(5)
        left_layout.setSpacing(20)
        left_widget = QWidget()
        left_widget.setLayout(left_layout)
        left_widget.setStyleSheet("""
            QWidget {
                background-color: #0073B9;            }
        """)

        self.right_widget = QTabWidget()
        self.right_widget.tabBar().setObjectName("mainTab")

        self.right_widget.addTab(self.home_tab, '')
        self.right_widget.addTab(self.grade_tab, '')
        self.right_widget.addTab(self.student_tab, '')
        self.right_widget.addTab(self.exam_tab, '')
        self.right_widget.addTab(self.stats_tab, '')

        self.right_widget.setCurrentIndex(0)
        self.right_widget.setStyleSheet('''QTabBar::tab{width: 0; \
            height: 0; margin: 0; padding: 0; border: none;}''')

        main_layout = QHBoxLayout()
        main_layout.addWidget(left_widget)
        main_layout.addWidget(self.right_widget)
        main_layout.setStretch(0, 40)
        main_layout.setStretch(1, 200)
        main_layout.setSpacing(0)  # Kein Abstand zwischen Widgets
        main_layout.setContentsMargins(0, 0, 0, 0)  # Keine äußeren Ränder
        main_widget = QWidget()
        main_widget.setLayout(main_layout)
        self.setCentralWidget(main_widget)


    
    def home_page(self):
        main_layout = QVBoxLayout()
        main_layout.addWidget(QLabel('page 1'))
        main_layout.addStretch(5)
        main = QWidget()
        main.setLayout(main_layout)
        return main

    def grade_page(self):
        main_layout = QVBoxLayout()
        main_layout.addWidget(QLabel('page 2'))
        main_layout.addStretch(5)
        main = QWidget()
        main.setLayout(main_layout)
        return main

    def student_page(self):
        main_layout = QVBoxLayout()
        main_layout.addWidget(QLabel('page 3'))
        main_layout.addStretch(5)
        main = QWidget()
        main.setLayout(main_layout)
        return main

    def exam_page(self):
        main_layout = QVBoxLayout()
        main_layout.addWidget(QLabel('page 4'))
        main_layout.addStretch(5)
        main = QWidget()
        main.setLayout(main_layout)
        return main
    
    def stats_page(self):
        main_layout = QVBoxLayout()
        main_layout.addWidget(QLabel('page 5'))
        main_layout.addStretch(5)
        main = QWidget()
        main.setLayout(main_layout)
        return main