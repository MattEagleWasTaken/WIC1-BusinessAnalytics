# Author: Marvin Fischer (Matriculation Number: 86186)

# This application was fully developed by the author.
# The author is responsible for the complete implementation,
# including UI design, server logic, data handling, and visualizations.


# This server function contains the complete back-end logic of the Shiny dashboard.
server <- function(input, output, session) {
  
library(DBI)
library(RPostgres)
library(jsonlite)
library(shinyjs)
library(ggplot2)
  
  
# ---------------- Load DB Credentials ----------------
db_config <- fromJSON("../user_login_config.json")
  
con <- dbConnect(
    RPostgres::Postgres(),
    dbname   = db_config$database,
    host     = db_config$host,
    port     = db_config$port,
    user     = db_config$username,
    password = db_config$password
  )
  
# ---------------- Load Student Data ----------------
  students <- dbGetQuery(con, "
    SELECT matriculation_number, first_name, last_name FROM student
  ")
  
  students_sorted_matr <- students[order(students$matriculation_number), ]
  students_sorted_name <- students[order(students$last_name, students$first_name), ]
  students_sorted_name$full_name <- paste0(
    students_sorted_name$first_name, " ",
    students_sorted_name$last_name,
    " (", students_sorted_name$matriculation_number, ")"
  )
  
  name_choices <- c("- not selected -", students_sorted_name$full_name)
  matr_choices <- c("- not selected -", students_sorted_matr$matriculation_number)
  
  
#---------------------------------------------------------------------------------
# Dynamic Input Row (for "One Student")

  output$one_student_filters <- renderUI({
    
    req(input$student_toggle == "One Student")
    
    name_selected <- !is.null(input$name_select) &&
      input$name_select != "- not selected -"
    
    matr_selected <- !is.null(input$matnr_select) &&
      input$matnr_select != "- not selected -"
    
    div(
      style = "display: flex; align-items: flex-start; gap: 15px; margin-top: 20px;",
      
      # ---------------- Student Name ----------------
      if (!matr_selected) {
        selectInput(
          "name_select",
          label = tags$label(
            "Student Name:",
            style = "margin-top: 6px;"
          ),
          choices  = name_choices,
          selected = input$name_select %||% "- not selected -"
        )
      } else {
        div(
          class = "static-text-container",
          style = "margin-top: 0px;",
          
          tags$label(
            "Student Name:",
            style = "margin-top: 6px;"
          ),
          
          div(
            class = "static-text-input",
            style = "margin-top: 5px; box-shadow: 0px 2px 6px rgba(0,0,0,0.2);",
            {
              row <- students_sorted_name[
                students_sorted_name$matriculation_number == input$matnr_select,
              ]
              paste(row$first_name, row$last_name)
            }
          )
        )
      },
      
      # ---------------- Matriculation Number ----------------
      if (!name_selected) {
        selectInput(
          "matnr_select",
          label = tags$label(
            "Matriculation Number:",
            style = "margin-top: 6px;"
          ),
          choices  = matr_choices,
          selected = input$matnr_select %||% "- not selected -"
        )
      } else {
        div(
          class = "static-text-container",
          style = "margin-top: 0px;",
          
          tags$label(
            "Matriculation Number:",
            style = "margin-top: 6px;"
          ),
          
          div(
            class = "static-text-input",
            style = "margin-top: 5px; box-shadow: 0px 2px 6px rgba(0,0,0,0.2);",
            {
              sub(".*\\((.*)\\)$", "\\1", input$name_select)
            }
          )
        )
      },
      
      # ---------------- Reset Button ----------------
      actionButton(
        "reset_filters",
        "Reset",
        class = "reset-btn",
        style = "margin-top:35px; box-shadow: 0px 2px 6px rgba(0,0,0,0.2);"
      )
    )
  })
  
 
# ---------------------------------------------------------------------------------
# Show / Hide Reset Button
  observe({
    if (
      (!is.null(input$name_select) && input$name_select != "- not selected -") ||
      (!is.null(input$matnr_select) && input$matnr_select != "- not selected -")
    ) {
      shinyjs::show("reset_filters")
    } else {
      shinyjs::hide("reset_filters")
    }
  })
  
  
# ---------------------------------------------------------------------------------
# Reset all dropdowns
  observeEvent(input$reset_filters, {
    updateSelectInput(session, "name_select", selected = "- not selected -")
    updateSelectInput(session, "matnr_select", selected = "- not selected -")
  
    # Set bar plot data to NULL
    student_grades_for_plot(NULL)
    
    })
  
#  ---------------------------------------------------------------------------------
# All Average Grades of all Students
all_student_averages <- dbGetQuery(
  con,
"
SELECT 
    g.matriculation_number,
    AVG(g.grade) AS student_avg
  FROM grade g
  GROUP BY g.matriculation_number
  "
)  

# Mean of all Student averages  
overall_average <- mean(all_student_averages$student_avg, na.rm = TRUE)  

# SD of all Students
overall_sd <- sd(all_student_averages$student_avg, na.rm = TRUE) 
  
    
# ---------------------------------------------------------------------------------
# All Grades for selected student
student_grades_for_plot <- reactiveVal(NULL)
  
  
output$student_gpa <- renderText({
    
# ---------------- If All Students Mode ------------------------------------------------
  if (input$student_toggle == "All Students") {
    
    if (is.null(all_student_averages) || nrow(all_student_averages) == 0)
      return("-")
    
    # Average grade + SD in smaller font
      return(paste0(round(overall_average, 2), " ± ", round(overall_sd, 2)))  
    }
          
# ---------------- One Student Mode ---------------------------------------------------    
    req(input$student_toggle == "One Student")
    
    selected_matr <- input$matnr_select
    selected_name <- input$name_select
    
    # Resolve matriculation number
    if (!is.null(selected_matr) && selected_matr != "- not selected -") {
      matr <- selected_matr
    } else if (!is.null(selected_name) && selected_name != "- not selected -") {
      matr <- sub(".*\\((.*)\\)$", "\\1", selected_name)
    } else {
      return("-")
    }
    
    # Load grades + exam titles
    student_grades <- dbGetQuery(
      con,
      paste0("
      SELECT g.grade, g.grade_date, e.title AS exam_title
      FROM grade g
      JOIN exam e ON g.pnr = e.pnr
      WHERE g.matriculation_number = '", matr, "'
    ")
    )
    
    # saves grades for student plot
    student_grades_for_plot(student_grades)
    
    # Average Grade Calculation stays unchanged
    if (nrow(student_grades) == 0) return("-")
    
    round(mean(student_grades$grade, na.rm = TRUE), 2)
    
  })
  
 #----- Dynamic Average Grade Text Output-------------------------------------- 
  output$gpa_title <- renderUI({
    title <- if (input$student_toggle == "All Students") {
      HTML("Overall<br>Average Grade")
    } else {
      HTML("Student<br>Average Grade")
    }
    
    h3(
      title,
      style = "
      margin: 0;
      margin-bottom: 10px;
      font-size: 20px;
      font-weight: bold;
      text-align: center;
    "
    )
  })

# ---------------------------------------------------------------------------------
# Grades horizontal bar plot
  output$grades_plot <- renderPlot({
    df <- student_grades_for_plot()
    if (is.null(df) || nrow(df) == 0) return(NULL)
    
    # Assign colors based on grade ranges (4 levels)
    df$color <- with(df,
                     ifelse(grade <= 1.5, "#3c8d40",        # Very Good
                     ifelse(grade <= 2.5, "#88c999",        # Good
                     ifelse(grade <= 3.5, "#f3b173",        # Average
                     ifelse(grade <= 4.0, "#e16b6b",        # Below Average
                     "#8b0000"))))                          # Failed (>4.0)
                     )                
    
    # Order exams: best grade (lowest value) on top
    df$exam_title <- factor(df$exam_title, levels = rev(df$exam_title[order(df$grade)]))
    
    
    # Resolve student full name for dynamic title
    
    student_name <- NULL
    
    if (input$student_toggle == "One Student") {
      
      if (!is.null(input$name_select) &&
          input$name_select != "- not selected -") {
        
        student_name <- sub(" \\(.*\\)$", "", input$name_select)
        
      } else if (!is.null(input$matnr_select) &&
                 input$matnr_select != "- not selected -") {
        
        row <- students_sorted_name[
          students_sorted_name$matriculation_number == input$matnr_select,
        ]
        
        if (nrow(row) == 1) {
          student_name <- row$full_name
        }
      }
    }
    
    
    ggplot(df, aes(x = grade, y = exam_title, fill = color)) +
      geom_col(width = 0.6, color = "black", show.legend = FALSE) +
      # Add grade labels inside the bars
      geom_text(aes(label = grade),
                position = position_stack(vjust = 0.5),
                color = "black",
                size = 5,
                fontface = "bold") +
      # X-axis from 1 (left) to 6 (right) with breaks
      scale_x_continuous(
        breaks = 1:6,
        labels = 1:6,
        expand = expansion(mult = c(0.02, 0.05))
      ) +
      scale_fill_identity() +  # Use actual hex colors
      labs(
        x = "Grade",
        y = "Exam",
        title = if (!is.null(student_name)) {
          paste0("Student Grades Overview – ", student_name)
        } else {
          "Student Grades Overview"
        }
      ) +
      theme_minimal(base_size = 14) +
      theme(
        plot.background  = element_rect(fill = "white", color = NA, linewidth = 0),
        panel.background = element_rect(fill = "white", color = "grey90", linewidth = 1),
        
        # Grid styling (consistent with One Exam histogram)
        panel.grid.major.y = element_line(
          color = "grey70",
          linewidth = 0.8
        ),
        panel.grid.major.x = element_line(
          color = "grey80",
          linewidth = 0.6
        ),
        panel.grid.minor = element_blank(),
        plot.title       = element_text(face = "bold", hjust = 0.5, size = 18),
        axis.text        = element_text(face = "bold", color = "black"),
        axis.title       = element_text(face = "bold", size = 14),
        axis.text.x = element_text(face = "plain", color = "black", size = 14),  
        axis.text.y = element_text(face = "plain", color = "black", size = 14)
      )
  })
  
# ---------------------------------------------------------------------------------
# Pie Plot
total_students <- nrow(all_student_averages)
  
  output$pie_plot <- renderPlot({
    
    df <- all_student_averages
    
    if (nrow(df) == 0) {
      return(NULL)
    }
    
    # Create grade clusters with ranges in labels
    df$cluster <- cut(
      df$student_avg,
      breaks = c(0, 1.5, 2.5, 3.5, 4.0, 6.0),
      labels = c(
        "Very Good (≤1.5)",
        "Good (1.6–2.5)",
        "Average (2.6–3.5)",
        "Below Average (3.6–4.0)",
        "Failed (>4.0)"
      ),
      include.lowest = TRUE,
      right = TRUE
    )
    
    # Count number of students per cluster
    df_clustered <- aggregate(matriculation_number ~ cluster, data = df, FUN = length)
    names(df_clustered)[2] <- "count"
    
    if (nrow(df) == 0) {
      return(NULL)
    }
    
    # Calculate percentages
    df_clustered$percent <- round(df_clustered$count / sum(df_clustered$count) * 100, 1)
    
    # Build combined slice label: "XX% (YY)"
    df_clustered$label <- paste0(df_clustered$percent, "% (", df_clustered$count, ")")
    
    # Pie chart
    ggplot(df_clustered, aes(x = "", y = count, fill = cluster)) +
      geom_bar(stat = "identity", width = 1, color = "black") +  
      geom_text(
        aes(label = label),
        position = position_stack(vjust = 0.5),
        size = 8,
        fontface = "bold"
      ) +
      coord_polar("y") +
      scale_fill_manual(
        values = c(
          "Very Good (≤1.5)" = "#3c8d40",
          "Good (1.6–2.5)"   = "#88c999",
          "Average (2.6–3.5)"= "#f3b173",
          "Below Average (3.6–4.0)"    = "#e16b6b",
          "Failed (>4.0)"           = "#8b0000"
        ),
        drop = FALSE
      ) +
      labs(
        title = "Overall Performance Overview",
        subtitle = paste("Total number of students:", total_students),
        fill  = "Grade Cluster"
      ) +
      theme_void() +
      theme(
        plot.title    = element_text(size = 20, face = "bold", hjust = 0.5, margin = margin(b = 5)),
        plot.subtitle = element_text(size = 16, face = "bold", hjust = 0.5, margin = margin(b = 10)),
        legend.title  = element_text(size = 16),
        legend.text   = element_text(size = 14),
        legend.position = "right"
      )
  })
  
# ---------------------------------------------------------------------------------
# switch between pie plot all students, or bar plot one student 
observe({
    req(input$student_toggle)
    
    if (input$student_toggle == "One Student") {
      shinyjs::show("student_plot_container1")
      shinyjs::hide("student_plot_container2")
    } else {
      shinyjs::hide("student_plot_container1")
      shinyjs::show("student_plot_container2")
    }
  })
  
  
# ---------------------------------------------------------------------------------
# Box Plot
output$boxplot_avg <- renderPlot({
    
    df <- all_student_averages
    if (nrow(df) == 0) return(NULL)
    
    # Overall statistics
    overall_mean   <- overall_average
    overall_median <- median(df$student_avg, na.rm = TRUE)
    overall_sd     <- sd(df$student_avg, na.rm = TRUE)
    
    p <- ggplot(df, aes(x = 1, y = student_avg)) +
      
      # Standard boxplot
      geom_boxplot(
        width = 0.5,
        fill = "lightblue",
        color = "black"
      ) +
      
      # Overall mean (blue line)
      annotate(
        "segment",
        x = 0.75, xend = 1.25,
        y = overall_mean, yend = overall_mean,
        color = "blue",
        linewidth = 1.2
      ) +
      
      # Mean label (left)
      annotate(
        "text",
        x = 0.725,
        y = overall_mean,
        label = paste0("Mean: ", round(overall_mean, 2)),
        hjust = 1,
        vjust = 0.5,
        color = "blue",
        size = 4,
        fontface = "bold"
      ) +
      
      # Median label (right)
      annotate(
        "text",
        x = 1.275,
        y = overall_median,
        label = paste0("Median: ", round(overall_median, 2)),
        hjust = 0,
        vjust = 0.5,
        color = "black",
        size = 4,
        fontface = "bold"
      ) +
      
      labs(
        y = "Average Grade",
        x = NULL,
        title = "Distribution of Average Grades\nAcross All Students",
        subtitle = paste0(
          "Median: ", round(overall_median, 2),
          "   |   SD: ", round(overall_sd, 2)
        )
      ) +
      
      scale_x_continuous(limits = c(0.4, 1.6)) +
      
      theme_minimal(base_size = 14) +
      theme(
        plot.title    = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 14, hjust = 0.5),
        
        axis.text.x   = element_blank(),
        axis.ticks.x  = element_blank(),
        axis.text.y   = element_text(face = "bold", size = 12, color = "black"),
        
        # ------------------------------------------------------------
        # Grid styling (same as bar plot / histogram)
        panel.grid.major.y = element_line(
          color = "grey70",
          linewidth = 0.8
        ),
        panel.grid.major.x = element_line(
          color = "grey85",
          linewidth = 0.6
        ),
        panel.grid.minor = element_blank()
      )
    
# ----------------------------------------------------
# Add student mean (red line)
if (input$student_toggle == "One Student") {
      
      df_student <- student_grades_for_plot()
      
      if (!is.null(df_student) && nrow(df_student) > 0) {
        
        student_mean <- mean(df_student$grade, na.rm = TRUE)
        
        p <- p +
          annotate(
            "segment",
            x = 0.75, xend = 1.25,
            y = student_mean, yend = student_mean,
            color = "red",
            linewidth = 1.2
          ) +
          # Label on the right of the box
          annotate(
            "text",
            x = 1.27,
            y = student_mean,
            label = paste0("Student: ", round(student_mean, 2)),
            hjust = 0,
            vjust = 0.5,
            color = "red",
            size = 4,
            fontface = "bold"
          )
      }
    }
    
    # show plot
    p
    
  })

# ---------------------------------------------------------------------------------
# Load Exam Data for the dropdowns
exams <- dbGetQuery(
    con,
    "
  SELECT
    pnr,
    title,
    semester
  FROM exam
  "
  )

# Create display label: Exam (Semester)
  exams$display_exam <- paste0(
    exams$title,
    " (", exams$semester, ")"
  )
  
# ---- Semester dropdown choices ------------------------------------
semester_choices_exam <- c(
    "- all semester -",
    sort(unique(exams$semester))
  )

# ---------------------------------------------------------------------------------
# Semester Filter 
output$exam_semester_filter <- renderUI({
    selectInput(
      "exam_semester_select",
      label    = tags$label("Semester:", style = "margin-top: 26px;"),
      choices  = semester_choices_exam,
      selected = "- all semester -"
    )
  })

# ---------------------------------------------------------------------------------
# Exams filtered by semester
filtered_exams <- reactive({
    
    df <- exams
    semester <- input$exam_semester_select
    
    if (!is.null(semester) && semester != "- all semester -") {
      df <- df[df$semester == semester, ]
    }
    
    df
  })
  
# ---------------------------------------------------------------------------------
# Dropdown choices
exam_title_choices_one <- reactive({
    c(
      "- not selected -",
      unique(filtered_exams()$display_exam)
    )
  })
  
  exam_pnr_choices_one <- reactive({
    c(
      "- not selected -",
      sort(unique(filtered_exams()$pnr))
    )
  })
  
# ---------------------------------------------------------------------------------
# Dynamic Input Row (for "One Exam")
output$one_exam_filters <- renderUI({
    
    req(input$exam_toggle == "One Exam")
    
    title_selected <- !is.null(input$exam_title_select) &&
      input$exam_title_select != "- not selected -"
    
    pnr_selected <- !is.null(input$exam_pnr_select) &&
      input$exam_pnr_select != "- not selected -"
    
    div(
      style = "display: flex; align-items: flex-start; gap: 15px; margin-top: 20px;",
      
# ---------------- Exam Title ----------------
      if (!pnr_selected) {
        selectInput(
          "exam_title_select",
          label = tags$label(
            "Exam Title:",
            style = "margin-top: 6px;"
          ),
          choices  = exam_title_choices_one(),
          selected = input$exam_title_select %||% "- not selected -"
        )
      } else {
        div(
          class = "static-text-container",
          style = "margin-top: 0px;",
          
          tags$label(
            "Exam Title:",
            style = "margin-top: 6px;"
          ),
          
          div(
            class = "static-text-input",
            style = "margin-top: 5px;",
            filtered_exams()[
              filtered_exams()$pnr == input$exam_pnr_select,
            ]$display_exam
          )
        )
      },
      
# ---------------- Exam Number ----------------
      if (!title_selected) {
        selectInput(
          "exam_pnr_select",
          label = tags$label(
            "Exam Number:",
            style = "margin-top: 6px;"
          ),
          choices  = exam_pnr_choices_one(),
          selected = input$exam_pnr_select %||% "- not selected -"
        )
      } else {
        div(
          class = "static-text-container",
          style = "margin-top: 0px;",
          
          tags$label(
            "Exam Number:",
            style = "margin-top: 6px;"
          ),
          
          div(
            class = "static-text-input",
            style = "margin-top: 5px;",
            filtered_exams()[
              filtered_exams()$display_exam == input$exam_title_select,
            ]$pnr[1]
          )
        )
      },
      
# ---------------- Reset Button ----------------
      actionButton(
        "reset_exam_filters",
        "Reset",
        class = "reset-btn",
        style = "margin-top:35px;"
      )
    )
  })

# ---------------------------------------------------------------------------------
# Reset Logic (One Exam)
observeEvent(input$reset_exam_filters, {
    updateSelectInput(session, "exam_title_select", selected = "- not selected -")
    updateSelectInput(session, "exam_pnr_select",   selected = "- not selected -")
  })
  
  
# ---------------------------------------------------------------------------------
# Show / Hide Exam Reset Button
observe({
    if (
      (!is.null(input$exam_title_select) &&
       input$exam_title_select != "- not selected -") ||
      (!is.null(input$exam_pnr_select) &&
       input$exam_pnr_select != "- not selected -")
    ) {
      shinyjs::show("reset_exam_filters")
    } else {
      shinyjs::hide("reset_exam_filters")
    }
  })
  
  # ---------------------------------------------------------------------------------  
  # Load All Grades for All Exams 
  all_grades <- dbGetQuery(con, "
  SELECT
    g.grade,
    g.matriculation_number,
    g.pnr,
    e.title          AS exam_title,
    e.semester       AS semester,
    e.degree_program AS degree_program
  FROM grade g
  JOIN exam e ON g.pnr = e.pnr
")
  
  # Preserve exam order in plots
  all_grades$exam_title <- factor(
    all_grades$exam_title,
    levels = unique(all_grades$exam_title)
  )
  
  # ---------------------------------------------------------------------------------
  # CENTRAL DATASET (All Exams + Semester filter)
  filtered_grades <- reactive({
    
    req(all_grades)
    
    df <- all_grades
    
    if (!is.null(input$exam_semester_select) &&
        input$exam_semester_select != "- all semester -") {
      df <- df[df$semester == input$exam_semester_select, ]
    }
    
    req(nrow(df) > 0)
    df
  })
  
  # ---------------------------------------------------------------------------------
  # SELECTED EXAM – AVERAGE (One Exam)
  selected_exam_avg <- reactive({
    
    req(input$exam_toggle == "One Exam")
    df <- all_grades
    req(nrow(df) > 0)
    
    if (!is.null(input$exam_pnr_select) &&
        input$exam_pnr_select != "- not selected -") {
      
      pnr <- input$exam_pnr_select
      
    } else if (!is.null(input$exam_title_select) &&
               input$exam_title_select != "- not selected -") {
      
      pnr <- filtered_exams()[
        filtered_exams()$display_exam == input$exam_title_select,
      ]$pnr[1]
      
    } else {
      return(NULL)
    }
    
    df <- df[df$pnr == pnr, ]
    mean(df$grade, na.rm = TRUE)
  })
  
  # ---------------------------------------------------------------------------------
  # ALL GRADES OF SELECTED EXAM (Barplot – One Exam)
  selected_exam_grades <- reactive({
    
    req(input$exam_toggle == "One Exam")
    df <- all_grades
    req(nrow(df) > 0)
    
    if (!is.null(input$exam_pnr_select) &&
        input$exam_pnr_select != "- not selected -") {
      
      pnr <- input$exam_pnr_select
      
    } else if (!is.null(input$exam_title_select) &&
               input$exam_title_select != "- not selected -") {
      
      pnr <- filtered_exams()[
        filtered_exams()$display_exam == input$exam_title_select,
      ]$pnr[1]
      
    } else {
      return(NULL)
    }
    
    df[df$pnr == pnr, ]
  })
  
  # ---------------------------------------------------------------------------------
  # LEFT PLOT 2: Grade Distribution – Selected Exam (One Exam Mode)
  output$exam_plot2 <- renderPlot({
    
    # Only relevant in One Exam mode
    req(input$exam_toggle == "One Exam")
    
    # Get all grades of the selected exam
    df <- selected_exam_grades()
    req(!is.null(df))
    req(nrow(df) > 0)
    
    # ------------------------------------------------------------
    # Define official grading scale 
    grade_levels <- c(
      "1", "1.3", "1.7",
      "2", "2.3", "2.7",
      "3", "3.3", "3.7",
      "4",
      "> 4.0"
    )
    
    # ------------------------------------------------------------
    # Color definition 
    grade_colors <- c(
      "Very Good (≤1.5)"        = "#3c8d40",
      "Good (1.6–2.5)"          = "#88c999",
      "Average (2.6–3.5)"       = "#f3b173",
      "Below Average (3.6–4.0)" = "#e16b6b",
      "Failed (>4.0)"           = "#8b0000"
    )
    
    # ------------------------------------------------------------
    # Collect all failing grades (> 4.0) into one category
    df$grade_plot <- ifelse(
      df$grade > 4.0,
      "> 4.0",
      as.character(df$grade)
    )
    
    # Convert grades to ordered factor
    df$grade_factor <- factor(
      df$grade_plot,
      levels = grade_levels,
      ordered = TRUE
    )
    
    # ------------------------------------------------------------
    # Count number of students per grade 
    grade_counts <- as.data.frame(table(df$grade_factor))
    names(grade_counts) <- c("grade", "count")
    
    # ------------------------------------------------------------
    # Assign performance cluster per grade level 
    grade_counts$grade_num <- suppressWarnings(
      as.numeric(as.character(grade_counts$grade))
    )
    
    grade_counts$grade_cluster <- cut(
      grade_counts$grade_num,
      breaks = c(0, 1.5, 2.5, 3.5, 4.0, Inf),
      labels = c(
        "Very Good (≤1.5)",
        "Good (1.6–2.5)",
        "Average (2.6–3.5)",
        "Below Average (3.6–4.0)",
        "Failed (>4.0)"
      ),
      include.lowest = TRUE,
      right = TRUE
    )
    
    grade_counts$grade_cluster[grade_counts$grade == "> 4.0"] <- "Failed (>4.0)"
    
    grade_counts$grade_cluster <- factor(
      grade_counts$grade_cluster,
      levels = names(grade_colors)
    )
    
    # ------------------------------------------------------------
    # Exam average for reference line
    ex_avg <- selected_exam_avg()
    req(is.finite(ex_avg))
    
    numeric_levels <- c(
      1.0, 1.3, 1.7,
      2.0, 2.3, 2.7,
      3.0, 3.3, 3.7,
      4.0
    )
    
    mean_grade <- min(ex_avg, 4.0)
    mean_level <- min(numeric_levels[numeric_levels >= mean_grade])
    mean_x <- which(grade_levels == as.character(mean_level))
    
    req(length(mean_x) == 1)
    
    n_students <- nrow(df)
    exam_title <- unique(df$exam_title)
    
    # ------------------------------------------------------------
    # Resolve semester label for subtitle
    semester_label <- ""
    
    if (!is.null(input$exam_semester_select) &&
        input$exam_semester_select != "- all semester -") {
      
      semester_label <- paste0("Semester: ", input$exam_semester_select, " | ")
    }
    
    # ------------------------------------------------------------
    # Plot
    ggplot(grade_counts, aes(x = grade, y = count)) +
      
      geom_col(
        aes(fill = grade_cluster),
        color = "black",
        width = 0.7
      ) +
      
      scale_fill_manual(
        name   = "Grade Cluster",
        values = grade_colors,
        drop   = TRUE
      ) +
      
      # ------------------------------------------------------------
    # Show count labels near the bottom of each bar
    geom_text(
      aes(label = ifelse(count > 0, count, "")),
      y = 0.5,
      fontface = "bold",
      size = 5,
      color = "black",
      vjust = 0
    ) +
      
      # ------------------------------------------------------------
    # Mean reference line + label
    geom_vline(
      xintercept = mean_x,
      color = "red",
      linewidth = 1.2
    ) +
      
      annotate(
        "text",
        x = mean_x,
        y = 0.25,
        label = paste0("Mean: ", round(ex_avg, 2)),
        color = "red",
        fontface = "bold",
        size = 4,
        hjust = -0.1
      ) +
      
      labs(
        title = paste0("Grade Distribution – ", exam_title),
        subtitle = paste0(
          semester_label,
          "Number of student exam results: ",
          n_students
        ),
        x = "Grade",
        y = "Number of grades"
      ) +
      
      scale_y_continuous(
        breaks = seq(0, max(grade_counts$count), by = 1),
        expand = expansion(mult = c(0, 0.15))
      ) +
      
      theme_minimal(base_size = 14) +
      theme(
        plot.title    = element_text(face = "bold", size = 18, hjust = 0.5),
        plot.subtitle = element_text(size = 14, hjust = 0.5),
        axis.title.x  = element_text(face = "bold", size = 14),
        axis.title.y  = element_text(face = "bold", size = 14),
        axis.text.x   = element_text(face = "bold", size = 12),
        axis.text.y   = element_text(size = 12),
        panel.grid.major.y = element_line(color = "grey70", linewidth = 0.8),
        panel.grid.major.x = element_line(color = "grey85", linewidth = 0.6),
        panel.grid.minor   = element_blank()
      )
  })
  
  # ---------------------------------------------------------------------------------
  # LEFT PLOT 1: Scatter Plot (All Exams Mode)
  output$exam_plot1 <- renderPlot({
    
    req(input$exam_toggle == "All Exams")
    
    # Dynamic subtitle depending on semester selection
    plot_subtitle <- NULL
    
    if (!is.null(input$exam_semester_select) &&
        input$exam_semester_select != "- all semester -") {
      
      plot_subtitle <- paste0("Semester: ", input$exam_semester_select)
    }
    
    df <- filtered_grades()
    req(!is.null(df))
    req(nrow(df) > 0)
    
    # ------------------------------------------------------------
    # Create unique exam label for Y-axis
    df$exam_label <- paste0(df$pnr, " – ", df$exam_title)
    df$exam_label <- factor(df$exam_label, levels = unique(df$exam_label))
    
    # ------------------------------------------------------------
    # Color definition for grade clusters
    grade_colors <- c(
      "Very Good (≤1.5)"        = "#3c8d40",
      "Good (1.6–2.5)"          = "#88c999",
      "Average (2.6–3.5)"       = "#f3b173",
      "Below Average (3.6–4.0)" = "#e16b6b",
      "Failed (>4.0)"           = "#8b0000"
    )
    
    # ------------------------------------------------------------
    # Assign grade clusters
    df$cluster <- cut(
      df$grade,
      breaks = c(0, 1.5, 2.5, 3.5, 4.0, Inf),
      labels = c(
        "Very Good (≤1.5)",
        "Good (1.6–2.5)",
        "Average (2.6–3.5)",
        "Below Average (3.6–4.0)",
        "Failed (>4.0)"
      ),
      include.lowest = TRUE,
      right = TRUE
    )
    
    # ------------------------------------------------------------
    # Scatter plot
    ggplot(df, aes(y = exam_label, x = grade, color = cluster)) +
      
      # Grade threshold reference lines
      geom_vline(
        xintercept = c(1.5, 2.5, 3.5, 4.0),
        color = "black",
        linewidth = 0.5
      ) +
      
      # Individual student grades
      geom_jitter(
        height = 0,
        size   = 3,
        alpha  = 1
      ) +
      
      # Manual color scale
      scale_color_manual(
        values = grade_colors,
        drop   = FALSE
      ) +
      
      # Labels
      labs(
        title = "All Student Grades per Exam",
        subtitle = plot_subtitle,
        x     = "Grade",
        y     = "Exam",
        color = "Grade Cluster"
      ) +
      
      # Theme 
      theme_minimal(base_size = 14) +
      theme(
        plot.title       = element_text(face = "bold", size = 18, hjust = 0.5),
        plot.subtitle = element_text(face = "plain",size = 14,hjust = 0.5,margin = margin(t = 0, b = 10)),
        axis.title.x     = element_text(face = "bold", size = 16),
        axis.title.y     = element_text(face = "bold", size = 16),
        axis.text.x      = element_text(size = 14),
        axis.text.y      = element_text(size = 12),
        panel.grid.major = element_line(color = "grey70"),
        panel.grid.minor = element_line(color = "grey85"),
        legend.title     = element_text(face = "bold", size = 14),
        legend.text      = element_text(size = 12)
      )
  })
  
  # ---------------------------------------------------------------------------------
  # Dynamic plotOutput height for exam_plot1
  output$exam_plot1_ui <- renderUI({
    
    req(input$exam_toggle == "All Exams")
    
    df <- filtered_grades()
    req(!is.null(df))
    req(nrow(df) > 0)
    
    # Use unique exam labels (PNR + title) for height calculation
    exam_labels <- paste0("PNR ", df$pnr, " – ", df$exam_title)
    n_exams <- length(unique(exam_labels))
    
    # Height grows with number of exams (enables scrolling)
    h <- max(400, n_exams * 35)
    
    plotOutput(
      "exam_plot1",
      height = paste0(h, "px"),
      width  = "100%"
    )
  })
  
  
  # ---------------------------------------------------------------------------------
  # COMPARISON SPACE FOR BOXPLOT (Semester based)
  exam_comparison_averages <- reactive({
    
    df <- all_grades
    req(nrow(df) > 0)
    
    if (!is.null(input$exam_semester_select) &&
        input$exam_semester_select != "- all semester -") {
      df <- df[df$semester == input$exam_semester_select, ]
    }
    
    req(nrow(df) > 0)
    
    aggregate(grade ~ exam_title, data = df, FUN = mean)
  })
  
  # ----------------------------------------------------------------------------
  # Box Plot Distribution of Exam Average Grades 
  output$exam_boxplot_avg <- renderPlot({
    
    
    # Dynamic title depending on semester selection
    title_suffix <- ""
    
    if (!is.null(input$exam_semester_select) &&
        input$exam_semester_select != "- all semester -") {
      
      title_suffix <- paste0(input$exam_semester_select)
    }
    
    plot_title <- paste0(
      "Distribution of all\nExam Average Grades ",
      title_suffix
    )
    
    # --- new comparison space ---
    df <- exam_comparison_averages()
    req(nrow(df) > 1)
    
    # --- statistics (same meaning as before) ---
    stats <- list(
      mean   = mean(df$grade, na.rm = TRUE),
      median = median(df$grade, na.rm = TRUE),
      sd     = sd(df$grade, na.rm = TRUE)
    )
    
    # --- base plot (OLD DESIGN) ---
    p <- ggplot(df, aes(x = 1, y = grade)) +
      
      # ----------------------------------------------------
    # Boxplot of exam averages
    geom_boxplot(
      width = 0.5,
      fill  = "lightblue",
      color = "black"
    ) +
      
      # ----------------------------------------------------
    # Mean line (blue)
    annotate(
      "segment",
      x = 0.75, xend = 1.25,
      y = stats$mean, yend = stats$mean,
      color = "blue",
      linewidth = 1.2
    ) +
      
      # Mean label (left)
      annotate(
        "text",
        x = 0.72,
        y = stats$mean,
        label = paste0("Mean: ", round(stats$mean, 2)),
        hjust = 1,
        color = "blue",
        fontface = "bold",
        size = 4
      ) +
      
      # Median label (right)
      annotate(
        "text",
        x = 1.28,
        y = stats$median,
        label = paste0("Median: ", round(stats$median, 2)),
        hjust = 0,
        fontface = "bold",
        size = 4
      ) +
      
      # ----------------------------------------------------
    # Labels
    labs(
      title = plot_title,
      subtitle = paste0(
        "Median: ", round(stats$median, 2),
        "   |   SD: ", round(stats$sd, 2)
      ),
      y = "Average Grade",
      x = NULL
    ) +
      
      scale_x_continuous(limits = c(0.4, 1.6)) +
      
      # ----------------------------------------------------
    # Theme
    theme_minimal(base_size = 14) +
      theme(
        plot.title    = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 14, hjust = 0.5),
        
        axis.text.x   = element_blank(),
        axis.ticks.x  = element_blank(),
        axis.text.y   = element_text(face = "bold", size = 12, color = "black"),
        
        panel.grid.major.y = element_line(
          color = "grey70",
          linewidth = 0.8
        ),
        panel.grid.major.x = element_line(
          color = "grey85",
          linewidth = 0.6
        ),
        panel.grid.minor = element_blank()
      )
    
    # ----------------------------------------------------
    # One Exam mode
    if (input$exam_toggle == "One Exam") {
      
      ex_avg <- selected_exam_avg()
      
      if (!is.null(ex_avg) && is.numeric(ex_avg)) {
        
        p <- p +
          annotate(
            "segment",
            x = 0.75, xend = 1.25,
            y = ex_avg, yend = ex_avg,
            color = "red",
            linewidth = 1.2
          ) +
          annotate(
            "text",
            x = 1.28,
            y = ex_avg,
            label = paste0("Exam: ", round(ex_avg, 2)),
            hjust = 0,
            vjust = 0.5,
            color = "red",
            fontface = "bold",
            size = 4
          )
      }
    }
    
    p
  })
  
  # ---------------------------------------------------------------------------------
  # KPI VALUE
  output$exam_gpa_value <- renderText({
    
    if (input$exam_toggle == "All Exams") {
      df <- exam_comparison_averages()
      paste0(
        round(mean(df$grade), 2),
        " ± ",
        round(sd(df$grade), 2)
      )
    } else {
      ex_avg <- selected_exam_avg()
      if (is.null(ex_avg)) "-" else round(ex_avg, 2)
    }
  })
  
  # ---------------------------------------------------------------------------------
  # KPI TITLE
  output$exam_gpa_title <- renderUI({
    
    title <- if (input$exam_toggle == "All Exams") {
      if (is.null(input$exam_semester_select) ||
          input$exam_semester_select == "- all semester -") {
        HTML("Overall<br>Exam Average")
      } else {
        HTML("Semester<br>Exam Average")
      }
    } else {
      HTML("Exam<br>Average")
    }
    
    h3(
      title,
      style = "
      margin: 0;
      margin-bottom: 10px;
      font-size: 20px;
      font-weight: bold;
      text-align: center;
    "
    )
  })
  
  # ---------------------------------------------------------------------------------
  # SHOW / HIDE LEFT PLOTS
  observe({
    if (input$exam_toggle == "All Exams") {
      shinyjs::show("exam_plot_container1")
      shinyjs::hide("exam_plot_container2")
    } else {
      shinyjs::hide("exam_plot_container1")
      shinyjs::show("exam_plot_container2")
    }
  })

  
# ----------------------------------------------------------------------------
# Load Degree Program Data (incl. semester)
degrees <- dbGetQuery(
    con,
    "
  SELECT DISTINCT
    e.degree_program,
    e.semester
  FROM exam e
  ORDER BY e.degree_program, e.semester
  "
  )
  
# ---- Sort variants ----------------------------------------------------------
  degrees_sorted_prog <- degrees[order(degrees$degree_program), ]
  degrees_sorted_sem  <- degrees[order(degrees$semester), ]
  
# ---- Dropdown choices -------------------------------------------------------
  degree_choices   <- c("- not selected -", unique(degrees_sorted_prog$degree_program))
  semester_choices <- c("- all semester -", unique(degrees_sorted_sem$semester))
  
  
# ----------------------------------------------------------------------------
# Semester Filter 
output$degree_semester_filter <- renderUI({
    
    div(
      style = "display: flex; align-items: flex-start; gap: 15px; margin-top: 20px;",
      selectInput(
        "degree_semester_select",
        label    = tags$label("Semester:", style = "margin-top: 6px;"),
        choices  = semester_choices,
        selected = "- all semester -"
      )
    )
  })
  
# ----------------------------------------------------------------------------
# Degree programs filtered by semester
filtered_degrees_one <- reactive({
    
    df <- degrees
    semester <- input$degree_semester_select
    
    if (!is.null(semester) && semester != "- all semester -") {
      df <- df[df$semester == semester, ]
    }
    
    df
  })
  
  
# ----------------------------------------------------------------------------
# Degree program dropdown choices
degree_program_choices_one <- reactive({
    c(
      "- not selected -",
      sort(unique(filtered_degrees_one()$degree_program))
    )
  })
  
  
# ----------------------------------------------------------------------------
# Dynamic Input Row (for "One Program")
output$one_degree_filters <- renderUI({
    
    req(input$degree_toggle == "One Program")
    
    div(
      style = "display: flex; align-items: flex-start; gap: 15px; margin-top: 20px;",
      
      # ---------------- Degree Program ---------------------------------------
      selectInput(
        "degree_program_select",
        label    = tags$label("Degree Program:", style = "margin-top: 6px;"),
        choices  = degree_program_choices_one(),
        selected = input$degree_program_select %||% "- not selected -"
      ),
      
      # ---------------- Reset Button -----------------------------------------
      actionButton(
        "reset_degree_filters",
        "Reset",
        class = "reset-btn",
        style = "margin-top:35px; box-shadow: 0px 2px 6px rgba(0,0,0,0.2);"
      )
    )
  })
  
  
# ----------------------------------------------------------------------------
# Reset Degree Filters
observeEvent(input$reset_degree_filters, {
    updateSelectInput(session, "degree_program_select", selected = "- not selected -")
    updateSelectInput(session, "degree_semester_select", selected = "- all semester -")
  })
  
  
# ----------------------------------------------------------------------------
# Show / Hide Degree Reset Button
observe({
    if (!is.null(input$degree_program_select) &&
        input$degree_program_select != "- not selected -") {
      shinyjs::show("reset_degree_filters")
    } else {
      shinyjs::hide("reset_degree_filters")
    }
  })
 
# ----------------------------------------------------------------------------
# Exam averages per Degree Program
degree_exam_averages <- reactive({
    
    # Ensure the central grade dataset is available
    req(all_grades)
    
    # Start from the complete dataset
    df <- all_grades
    
# ------------------------------------------------------------
# Apply semester filter
if (!is.null(input$degree_semester_select) &&
        input$degree_semester_select != "- all semester -") {
      
      df <- df[df$semester == input$degree_semester_select, ]
    }
    
    # Ensure that data is still available after filtering
    req(nrow(df) > 0)
    
# ------------------------------------------------------------
# Aggregate grades
aggregate(
      grade ~ degree_program + pnr + exam_title,
      data = df,
      FUN  = mean
    )
})
  
# ----------------------------------------------------------------------------
# Scatter Plot
output$degree_plot1 <- renderPlot({
    
# "All Programs" mode
    req(input$degree_toggle == "All Programs")
    
# Get aggregated exam averages
    df <- degree_exam_averages()
    req(nrow(df) > 0)
    
# ------------------------------------------------------------
# Consistent color mapping
    grade_colors <- c(
      "Very Good (≤1.5)"        = "#3c8d40",
      "Good (1.6–2.5)"          = "#88c999",
      "Average (2.6–3.5)"       = "#f3b173",
      "Below Average (3.6–4.0)" = "#e16b6b",
      "Failed (>4.0)"           = "#8b0000"
    )
    
# Assign grade clusters
    df$cluster <- cut(
      df$grade,
      breaks = c(0, 1.5, 2.5, 3.5, 4.0, Inf),
      labels = c(
        "Very Good (≤1.5)",
        "Good (1.6–2.5)",
        "Average (2.6–3.5)",
        "Below Average (3.6–4.0)",
        "Failed (>4.0)"
      ),
      include.lowest = TRUE,
      right = TRUE
    )
    
    # fix legend order
    df$cluster <- factor(df$cluster, levels = names(grade_colors))
    

    
# ------------------------------------------------------------
# Scatter plot
ggplot(df, aes(
      y = degree_program,
      x = grade,
      color = cluster
    )) +
      
# Reference lines for grading thresholds
      geom_vline(
        xintercept = c(1.5, 2.5, 3.5, 4.0),
        color = "black",
        linewidth = 0.5
      ) +
      
# One jittered point per exam average
      geom_jitter(
        height = 0.15,
        size   = 3,
        alpha  = 1
      ) +
      
# Apply consistent color palette
      scale_color_manual(values = grade_colors) +
      
# Axis labels and title
      labs(
        title = "Exam Average Grades per Degree Program",
        subtitle = if (
          is.null(input$degree_semester_select) ||
          input$degree_semester_select == "- all semester -"
        ) {
          "All semesters"
        } else {
          paste("Semester:", input$degree_semester_select)
        },
        x = "Average Grade per Exam",
        y = "Degree Program",
        color = "Grade Cluster"
      ) +
      
# Theme consistent with Exam scatter plot
      theme_minimal(base_size = 14) +
      theme(
        plot.title       = element_text(face = "bold", size = 18, hjust = 0.5),
        plot.subtitle    = element_text(size = 14, hjust = 0.5),
        axis.title.x     = element_text(face = "bold", size = 16),
        axis.title.y     = element_text(face = "bold", size = 16),
        axis.text.x      = element_text(size = 14),
        axis.text.y      = element_text(size = 12),
        panel.grid.major = element_line(color = "grey70"),
        panel.grid.minor = element_line(color = "grey85"),
        legend.title     = element_text(face = "bold", size = 14),
        legend.text      = element_text(size = 12)
      )
  })
 
# ----------------------------------------------------------------------------
# Dynamic plotOutput height for Degree scatter plot
output$degree_plot1_ui <- renderUI({
    
    req(input$degree_toggle == "All Programs")
    
    df <- degree_exam_averages()
    req(nrow(df) > 0)
    
    # Height scales with number of degree programs
    n_degrees <- length(unique(df$degree_program))
    height_px <- max(400, n_degrees * 35)
    
    plotOutput(
      "degree_plot1",
      height = paste0(height_px, "px"),
      width  = "100%"
    )
})
  
# ----------------------------------------------------------------------------
# All individual grades for selected Degree Program
degree_program_grades <- reactive({
    
    req(input$degree_toggle == "One Program")
    req(input$degree_program_select)
    req(input$degree_program_select != "- not selected -")
    
    df <- all_grades
    
    # Semester filter (degree tab)
    if (!is.null(input$degree_semester_select) &&
        input$degree_semester_select != "- all semester -") {
      df <- df[df$semester == input$degree_semester_select, ]
    }
    
    # Degree program filter
    df <- df[df$degree_program == input$degree_program_select, ]
    
    req(nrow(df) > 0)
    
    df
  })
  
# ----------------------------------------------------------------------------
# Grade Distribution for One Degree Program
output$degree_plot2 <- renderPlot({
    
    req(input$degree_toggle == "One Program")
    
    df <- degree_program_grades()
    req(nrow(df) > 0)
    
# ------------------------------------------------------------
# Grading scale
    grade_levels <- c(
      "1", "1.3", "1.7",
      "2", "2.3", "2.7",
      "3", "3.3", "3.7",
      "4",
      "> 4.0"
    )
    
# ------------------------------------------------------------
# Color definition
grade_colors <- c(
      "Very Good (≤1.5)"        = "#3c8d40",
      "Good (1.6–2.5)"          = "#88c999",
      "Average (2.6–3.5)"       = "#f3b173",
      "Below Average (3.6–4.0)" = "#e16b6b",
      "Failed (>4.0)"           = "#8b0000"
    )
    
# ------------------------------------------------------------
# Collapse failing grades (>4.0)
    df$grade_plot <- ifelse(
      df$grade > 4.0,
      "> 4.0",
      as.character(df$grade))
    
    df$grade_factor <- factor(
      df$grade_plot,
      levels  = grade_levels,
      ordered = TRUE
    )
    
# ------------------------------------------------------------
# Count students per grade
    grade_counts <- as.data.frame(table(df$grade_factor))
    names(grade_counts) <- c("grade", "count")
    
# ------------------------------------------------------------
# Assign grade clusters
    grade_counts$grade_num <- suppressWarnings(
      as.numeric(as.character(grade_counts$grade))
    )
    
    grade_counts$grade_cluster <- cut(
      grade_counts$grade_num,
      breaks = c(0, 1.5, 2.5, 3.5, 4.0, Inf),
      labels = names(grade_colors),
      include.lowest = TRUE,
      right = TRUE
    )
    
    # failed assignment
    grade_counts$grade_cluster[
      grade_counts$grade == "> 4.0"
    ] <- "Failed (>4.0)"
    
    grade_counts$grade_cluster <- factor(
      grade_counts$grade_cluster,
      levels = names(grade_colors)
    )
    
# ------------------------------------------------------------
# Degree program average 
    program_mean <- mean(df$grade, na.rm = TRUE)
    req(is.finite(program_mean))
    
    numeric_levels <- c(
      1.0, 1.3, 1.7,
      2.0, 2.3, 2.7,
      3.0, 3.3, 3.7,
      4.0
    )
    
    # Clamp mean to plotting range
    mean_grade <- min(program_mean, 4.0)
    
    # Find next grade level
    mean_level <- min(numeric_levels[numeric_levels >= mean_grade])
    
    # Convert to x-position
    mean_x <- which(as.character(mean_level) == grade_levels)
    req(length(mean_x) == 1)
    
    n_students <- nrow(df)
    
# ------------------------------------------------------------
# Plot
    ggplot(grade_counts, aes(x = grade, y = count)) +
      
      geom_col(
        aes(fill = grade_cluster),
        color = "black",
        width = 0.7
      ) +
      
      scale_fill_manual(
        name   = "Grade Cluster",
        values = grade_colors
      ) +
      
      geom_text(
        aes(label = ifelse(count > 0, count, "")),
        y = 0.5,
        fontface = "bold",
        size = 5,
        vjust = 0
      ) +
      
      geom_vline(
        xintercept = mean_x,
        color = "blue",
        linewidth = 1.2
      ) +
      
      annotate(
        "text",
        x = mean_x,
        y = 0.25,
        label = paste0("Mean: ", round(program_mean, 2)),
        color = "blue",
        fontface = "bold",
        size = 4,
        hjust = -0.1
      ) +
      
      labs(
        title = paste0(
          "Grade Distribution – ",
          input$degree_program_select
        ),
        subtitle = paste0(
          if (
            !is.null(input$degree_semester_select) &&
            input$degree_semester_select != "- all semester -"
          ) paste0("Semester: ", input$degree_semester_select," | ") else "",
          "Number of student exam results: ", n_students
        ),
        x = "Grade",
        y = "Number of grades"
      ) +
      
      scale_y_continuous(
        breaks = seq(0, max(grade_counts$count), by = 1),
        expand = expansion(mult = c(0, 0.15))
      ) +
      
      theme_minimal(base_size = 14) +
      theme(
        plot.title    = element_text(face = "bold", size = 18, hjust = 0.5),
        plot.subtitle = element_text(size = 14, hjust = 0.5),
        axis.title.x  = element_text(face = "bold", size = 14),
        axis.title.y  = element_text(face = "bold", size = 14),
        axis.text.x   = element_text(face = "bold", size = 12),
        axis.text.y   = element_text(size = 12),
        panel.grid.major.y = element_line(color = "grey70", linewidth = 0.8),
        panel.grid.major.x = element_line(color = "grey85", linewidth = 0.6),
        panel.grid.minor   = element_blank()
      )
})
  
# ----------------------------------------------------------------------------
# Degree Boxplot Distribution of Exam Average Grades
output$degree_boxplot_all <- renderPlot({
    
# ------------------------------------------------------------
# exam averages per degree program
    df <- degree_exam_averages()
    req(nrow(df) > 1)
    
# ------------------------------------------------------------
# Overall statistics
    overall_mean   <- mean(df$grade, na.rm = TRUE)
    overall_median <- median(df$grade, na.rm = TRUE)
    overall_sd     <- sd(df$grade, na.rm = TRUE)
    
# ------------------------------------------------------------
# Boxplot
    p <- ggplot(df, aes(x = 1, y = grade)) +
      
      geom_boxplot(
        width = 0.5,
        fill  = "lightblue",
        color = "black"
      ) +
      
      annotate(
        "segment",
        x = 0.75, xend = 1.25,
        y = overall_mean, yend = overall_mean,
        color = "blue",
        linewidth = 1.2
      ) +
      
      annotate(
        "text",
        x = 0.72,
        y = overall_mean,
        label = paste0("Mean: ", round(overall_mean, 2)),
        hjust = 1,
        color = "blue",
        size = 4,
        fontface = "bold"
      ) +
      
      annotate(
        "text",
        x = 1.28,
        y = overall_median,
        label = paste0("Median: ", round(overall_median, 2)),
        hjust = 0,
        size = 4,
        fontface = "bold"
      ) +
      
      labs(
        title = "Distribution of Exam Average \nGrades Across Degree Programs",
        subtitle = paste0(
          "Median: ", round(overall_median, 2),
          " | SD: ", round(overall_sd, 2)
        ),
        y = "Average Grade",
        x = NULL
      ) +
      
      scale_x_continuous(limits = c(0.4, 1.6)) +
      
      theme_minimal(base_size = 14) +
      theme(
        plot.title    = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 14, hjust = 0.5),
        axis.text.x   = element_blank(),
        axis.ticks.x  = element_blank(),
        axis.text.y   = element_text(face = "bold", size = 12, color = "black"),
        panel.grid.major.y = element_line(color = "grey70", linewidth = 0.8),
        panel.grid.major.x = element_line(color = "grey85", linewidth = 0.6),
        panel.grid.minor   = element_blank()
      )
    
# ------------------------------------------------------------
# return plot
    p
})
  
  
# ----------------------------------------------------------------------------
# Boxplot – One Program
output$degree_boxplot_one <- renderPlot({
    
    req(input$degree_toggle == "One Program")
    req(input$degree_program_select)
    req(input$degree_program_select != "- not selected -")
    
# ------------------------------------------------------------
# all individual grades of the selected program

    df <- degree_program_grades()
    req(nrow(df) > 1)   # Boxplot needs more than one value
    
# ------------------------------------------------------------
# Statistics
    program_mean   <- mean(df$grade, na.rm = TRUE)
    program_median <- median(df$grade, na.rm = TRUE)
    program_sd     <- sd(df$grade, na.rm = TRUE)
    
# ------------------------------------------------------------
# Boxplot
    ggplot(df, aes(x = 1, y = grade)) +
      
      geom_boxplot(
        width = 0.5,
        fill  = "lightblue",
        color = "black"
      ) +
      
# ------------------------------------------------------------
# Mean reference line (blue)
    annotate(
      "segment",
      x = 0.75, xend = 1.25,
      y = program_mean, yend = program_mean,
      color = "blue",
      linewidth = 1.2
    ) +
      
# Mean label (left)
      annotate(
        "text",
        x = 0.72,
        y = program_mean,
        label = paste0("Mean: ", round(program_mean, 2)),
        hjust = 1,
        vjust = 0.5,
        color = "blue",
        size = 4,
        fontface = "bold"
      ) +
      
# Median label (right)
      annotate(
        "text",
        x = 1.28,
        y = program_median,
        label = paste0("Median: ", round(program_median, 2)),
        hjust = 0,
        vjust = 0.5,
        size = 4,
        fontface = "bold"
      ) +
      
      labs(
        title = if (
          is.null(input$degree_semester_select) ||
          input$degree_semester_select == "- all semester -"
        ) {
          "Distribution of Grades\n All Semesters"
        } else {
          paste0(
            "Distribution of Grades\n Semester ",
            input$degree_semester_select
          )
        },
        subtitle = paste0(
          "Median: ", round(program_median, 2),
          " | SD: ", round(program_sd, 2)
        ),
        y = "Grade",
        x = NULL
      ) +
      
      scale_x_continuous(limits = c(0.4, 1.6)) +
      
      theme_minimal(base_size = 14) +
      theme(
        plot.title    = element_text(size = 16, face = "bold", hjust = 0.5),
        plot.subtitle = element_text(size = 14, hjust = 0.5),
        
        axis.text.x   = element_blank(),
        axis.ticks.x  = element_blank(),
        axis.text.y   = element_text(face = "bold", size = 12, color = "black"),
        
        panel.grid.major.y = element_line(
          color = "grey70",
          linewidth = 0.8
        ),
        panel.grid.major.x = element_line(
          color = "grey85",
          linewidth = 0.6
        ),
        panel.grid.minor = element_blank()
      )
})

# ----------------------------------------------------------------------------
# Show / Hide Degree Tab
  observe({
    
    req(input$degree_toggle)
    
    if (input$degree_toggle == "All Programs") {
      
      shinyjs::show("degree_plot_container1")
      shinyjs::hide("degree_plot_container2")
      
    } else if (input$degree_toggle == "One Program") {
      
      shinyjs::hide("degree_plot_container1")
      shinyjs::show("degree_plot_container2")
    }
  })  
    
# ----------------------------------------------------------------------------
# Show / Hide Degree Boxplots
  observe({
    
    req(input$degree_toggle)
    
    if (input$degree_toggle == "All Programs") {
      
      shinyjs::show("degree_boxplot_all_container")
      shinyjs::hide("degree_boxplot_one_container")
      
    } else if (input$degree_toggle == "One Program") {
      
      shinyjs::hide("degree_boxplot_all_container")
      shinyjs::show("degree_boxplot_one_container")
    }
  })
  
  
# ----------------------------------------------------------------------------
# Statistics of degree exam averages
  degree_stats <- reactive({
    
    df <- degree_exam_averages()
    req(nrow(df) > 1)
    
    list(
      mean = mean(df$grade, na.rm = TRUE),
      sd   = sd(df$grade, na.rm = TRUE)
    )
})  

# ----------------------------------------------------------------------------
# Degree KPI Value Output (Upper Card)
  output$degree_card1_value <- renderText({
    
# ---------------- All Programs ----------------
    if (input$degree_toggle == "All Programs") {
      
      stats <- degree_stats()
      req(stats)
      
      return(
        paste0(
          round(stats$mean, 2),
          " ± ",
          round(stats$sd, 2)
        )
      )
    }
    
    # ---------------- One Program ----------------
    req(input$degree_toggle == "One Program")
    req(input$degree_program_select)
    req(input$degree_program_select != "- not selected -")
    
    df <- degree_program_grades()
    req(nrow(df) > 1)
    
    program_mean <- mean(df$grade, na.rm = TRUE)
    
    paste0(round(program_mean, 2))
})

# ----------------------------------------------------------------------------
# Dynamic title for Degree KPI card
  output$degree_card1_title <- renderUI({
    
    title <- if (input$degree_toggle == "All Programs") {
      
# Distinguish between overall and semester-specific aggregation
      if (is.null(input$degree_semester_select) ||
          input$degree_semester_select == "- all semester -") {
        
        HTML("Overall<br>Degree Program Average Grade")
        
      } else {
        
        HTML("Semester<br>Degree Program Average Grade")
      }
      
    } else {
      
# One Program mode
      HTML("Program<br>Average Grade")
    }
    
    h3(
      title,
      style = "
      margin: 0;
      margin-bottom: 10px;
      font-size: 20px;
      font-weight: bold;
      text-align: center;
    "
    )
})
  
  
# ----------------------------------------------------------------------------
# Disconnect when session ends
   session$onSessionEnded(function() {
    dbDisconnect(con)
  })
  
}
  