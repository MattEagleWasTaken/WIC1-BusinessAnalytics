"""
ALLGEMEINE TODOS:
[] Kommentare aufräumen
[x] Signal/Slot Logik für data.changed überdenken
[] ToDos im Code durchgehen 
[x] HomeScreen als Default weiß 
[] Evtl. StatsPage raus
[x] Evtl. neuer Stretch/ look Sidebar
"""

import os
from pages import ExamPage, GradePage, HomePage, StatsPage, StudentPage
from PySide6.QtCore import QSize, Slot, QTimer
from PySide6.QtGui import QIcon
from PySide6.QtWidgets import (QMainWindow, QPushButton, QStatusBar,
QHBoxLayout, QVBoxLayout, QWidget, QLabel, QTabWidget
)



class MainWindow(QMainWindow):
    """ MainWindow which contains the Sidebar-logic and calls the pages/tabs"""

    
    def __init__(self, app):
        """setup the main window, the relative image path, the GUI widgets and the main-window-layout"""
        super().__init__()
        self.app = app
        self.base_path = os.path.dirname(os.path.abspath(__file__)) 
        self.image_path = os.path.join(self.base_path, "Images")
        self.setup_window()
        self.home_btn_clicked()


    def setup_window(self):
        """setup the frame of the main window"""
        self.setWindowTitle("ExaMS")
        self.setMinimumSize(800, 700)  # min-size
        self.resize(800, 700)         # Startsize
        self.setStatusBar(QStatusBar(self))
        self.create_sidebar_buttons()
        self.setup_tabs()
        self.setup_layout()



    def create_sidebar_buttons(self):
        """create every sidebar-button, apply style and connect to functions"""
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
            """ update button icons if they are currently active/inactive"""
            self.home_btn.setIcon(self.home_btn_icon_active if self.home_btn.isChecked() else self.home_btn_icon_normal)
            self.grade_entry_btn.setIcon(self.grade_entry_btn_icon_active if self.grade_entry_btn.isChecked() else self.grade_entry_btn_icon_normal)
            self.student_entry_btn.setIcon(self.student_entry_btn_icon_active if self.student_entry_btn.isChecked() else self.student_entry_btn_icon_normal)
            self.exam_entry_btn.setIcon(self.exam_entry_btn_icon_active if self.exam_entry_btn.isChecked() else self.exam_entry_btn_icon_normal)
            self.stats_btn.setIcon(self.stats_btn_icon_active if self.stats_btn.isChecked() else self.stats_btn_icon_normal)

    
    def setup_tabs(self):
        """Tab-management for every page"""
        self.home_tab = HomePage()
        self.grade_tab = GradePage()
        self.student_tab = StudentPage()
        self.exam_tab = ExamPage()
        self.stats_tab = StatsPage()
        
        # Setting up Signals between MainWindow and different pages 
        self.home_tab.status_message.connect(self.show_status_message)
        self.grade_tab.data_changed.connect(self.handle_grade_data)
        self.grade_tab.status_message.connect(self.show_status_message)
        self.student_tab.data_changed.connect(self.handle_student_data)
        self.student_tab.status_message.connect(self.show_status_message)       
        self.exam_tab.data_changed.connect(self.handle_exam_data)
        self.exam_tab.status_message.connect(self.show_status_message)
        self.stats_tab.status_message.connect(self.show_status_message)

    # Slot to receive and display status messages from the individual pages
    @Slot(str)
    def show_status_message(self, message, timeout):
        self.statusBar().showMessage(message, timeout)

    # Slot to receive and display actual data from the individual pages
    @Slot(dict)
    def handle_grade_data(self, data):
        self.statusBar().showMessage(f"Saving grade {data['grade']} for student {data['student']}", 2000)

    def handle_student_data(self, data):
        self.statusBar().showMessage(f"Saving student {data['first_name']} {data['last_name']}", 2000)   

    def handle_exam_data(self, data):
        self.statusBar().showMessage(f"Creating Exam {data['exam_title']}", 2000)         



    def apply_sidebar_button_style(self, button):
        """
        apply style to each sidebar button
        Args:   
            button: the button to apply the style to
        """
        button.setCheckable(True)
        button.setChecked(False)
        button.setMinimumSize(QSize(100, 100))
        button.setMaximumSize(QSize(150, 150))
        button.setStyleSheet("""
            QPushButton {
                padding: 5px;
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
                border: 3px solid #FEFEFE;
                background-color: #FEFEFE;
            }
        """)

    def resizeEvent(self, event):
        """Resize Icon-size when resizing Window"""
        super().resizeEvent(event)
        self.update_icon_sizes()

    def update_icon_sizes(self):
        """Calculate icon size based in button size"""
        buttons = [
            self.home_btn, 
            self.grade_entry_btn, 
            self.student_entry_btn, 
            self.exam_entry_btn, 
            self.stats_btn
        ]
        
        for btn in buttons:
            btn_size = btn.size()
            icon_width = btn_size.width()  
            icon_height = btn_size.height()
            icon_size = min(icon_width, icon_height)
            icon_size = max(40, icon_size)  
            
            btn.setIconSize(QSize(icon_size, icon_size))

    def showEvent(self, event):
        """initial Icon-size when opening app"""
        super().showEvent(event)
        QTimer.singleShot(10, self.update_icon_sizes)


    def home_btn_clicked(self):
        """switch home button color and switch to tab"""
        self.uncheck_sidebar_buttons()
        self.home_btn.setChecked(True)
        self.update_button_icons()
        self.right_widget.setCurrentIndex(0)

    def grade_entry_btn_clicked(self):
        """switch grade-entry-button color and switch to tab"""       
        self.uncheck_sidebar_buttons()
        self.grade_entry_btn.setChecked(True)
        self.update_button_icons()
        self.right_widget.setCurrentIndex(1)

    def student_entry_btn_clicked(self):
        """switch student-entry-button color and switch to tab"""      
        self.uncheck_sidebar_buttons()
        self.student_entry_btn.setChecked(True)
        self.update_button_icons()
        self.right_widget.setCurrentIndex(2)

    def exam_entry_btn_clicked(self):
        """switch exam-entry-button color and switch to tab"""      
        self.uncheck_sidebar_buttons()
        self.exam_entry_btn.setChecked(True)
        self.update_button_icons()
        self.right_widget.setCurrentIndex(3)

    def stats_btn_clicked(self):
        """switch stats-button color and switch to tab"""      
        self.uncheck_sidebar_buttons()
        self.stats_btn.setChecked(True)
        self.update_button_icons()
        self.right_widget.setCurrentIndex(4)

    def uncheck_sidebar_buttons(self):
        """uncheck all sidebar buttons"""
        self.home_btn.setChecked(False)
        self.grade_entry_btn.setChecked(False)
        self.student_entry_btn.setChecked(False)
        self.exam_entry_btn.setChecked(False)
        self.stats_btn.setChecked(False)


    def setup_layout(self):
        """Create the MainWindow-Layout"""
        # === Sidebar / left Widget ===
        left_layout = QVBoxLayout()
        left_layout.addWidget(self.home_btn, 1)
        left_layout.addWidget(self.grade_entry_btn, 1)
        left_layout.addWidget(self.student_entry_btn, 1)
        left_layout.addWidget(self.exam_entry_btn, 1)
        left_layout.addWidget(self.stats_btn, 1)
        left_layout.addStretch(3)
        left_layout.setSpacing(10)


        left_widget = QWidget()
        left_widget.setLayout(left_layout)
        left_widget.setMinimumWidth(80)
        left_widget.setMaximumWidth(150)
        left_widget.setStyleSheet("""
            QWidget {
                background-color: #0073B9;            }
        """)

        # === Tabs / right Widget ===
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
        main_layout.addWidget(self.right_widget,1)
        main_layout.setStretch(0, 40)
        main_layout.setStretch(1, 200)
        main_layout.setSpacing(0) 
        main_layout.setContentsMargins(0, 0, 0, 0)  
        main_widget = QWidget()
        main_widget.setLayout(main_layout)
        self.setCentralWidget(main_widget)


