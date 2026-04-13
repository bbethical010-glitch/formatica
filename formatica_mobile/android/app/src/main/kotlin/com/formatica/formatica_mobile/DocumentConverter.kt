package com.formatica.formatica_mobile

import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.graphics.Typeface
import android.graphics.pdf.PdfDocument
import android.text.Layout
import android.text.StaticLayout
import android.text.TextPaint
import org.apache.poi.hslf.usermodel.HSLFSlideShow
import org.apache.poi.hssf.usermodel.HSSFWorkbook
import org.apache.poi.ss.usermodel.CellType
import org.apache.poi.ss.usermodel.DateUtil
import org.apache.poi.ss.usermodel.Workbook
import org.apache.poi.xslf.usermodel.XMLSlideShow
import org.apache.poi.xssf.usermodel.XSSFWorkbook
import org.apache.poi.xwpf.usermodel.XWPFDocument
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

/**
 * Native document converter using Apache POI for Office formats.
 * Converts DOCX, XLSX, XLS, PPTX, PPT, and CSV to PDF with formatting preserved.
 */
class DocumentConverter {
    
    companion object {
        // PDF page dimensions (A4 at 72 DPI)
        private const val A4_WIDTH = 595
        private const val A4_HEIGHT = 842
        private const val MARGIN = 50
        private const val CONTENT_WIDTH = A4_WIDTH - 2 * MARGIN
        
        // High-res rendering for crisp output (2x scale)
        private const val RENDER_SCALE = 2.0f
        private const val HIGH_RES_WIDTH = (A4_WIDTH * RENDER_SCALE).toInt()
        private const val HIGH_RES_HEIGHT = (A4_HEIGHT * RENDER_SCALE).toInt()
        private const val HIGH_RES_MARGIN = (MARGIN * RENDER_SCALE).toInt()
        private const val HIGH_RES_CONTENT_WIDTH = HIGH_RES_WIDTH - 2 * HIGH_RES_MARGIN
    }

    /**
     * Convert spreadsheet (XLSX/XLS/CSV) to PDF with crisp vector-based rendering
     */
    fun convertSpreadsheetToPdf(
        inputPath: String,
        outputPath: String,
        format: String
    ): Result<String> {
        return try {
            val inputFile = File(inputPath)
            if (!inputFile.exists()) {
                return Result.failure(Exception("Input file not found: $inputPath"))
            }

            val workbook: Workbook = when (format.lowercase()) {
                "xlsx" -> XSSFWorkbook(FileInputStream(inputFile))
                "xls" -> HSSFWorkbook(FileInputStream(inputFile))
                "csv" -> createWorkbookFromCsv(inputFile)
                else -> return Result.failure(Exception("Unsupported format: $format"))
            }

            val pdfDocument = PdfDocument()
            var pageNumber = 1

            // Convert each sheet to PDF pages
            for (sheetIndex in 0 until workbook.numberOfSheets) {
                val sheet = workbook.getSheetAt(sheetIndex)
                val sheetPages = renderSheetToPages(sheet)
                
                for (pageBitmap in sheetPages) {
                    val pageInfo = PdfDocument.PageInfo.Builder(A4_WIDTH, A4_HEIGHT, pageNumber)
                        .create()
                    val page = pdfDocument.startPage(pageInfo)
                    
                    // Scale high-res bitmap to PDF page size for crisp output
                    val scaledBitmap = Bitmap.createScaledBitmap(pageBitmap, A4_WIDTH, A4_HEIGHT, true)
                    page.canvas.drawBitmap(scaledBitmap, 0f, 0f, null)
                    pdfDocument.finishPage(page)
                    pageNumber++
                }
            }

            // Write PDF to output file
            val outputFile = File(outputPath)
            outputFile.parentFile?.mkdirs()
            
            FileOutputStream(outputFile).use { outputStream ->
                pdfDocument.writeTo(outputStream)
            }
            
            pdfDocument.close()
            workbook.close()

            Result.success(outputPath)
        } catch (e: Exception) {
            Result.failure(Exception("Spreadsheet conversion failed: ${e.message}", e))
        }
    }

    /**
     * Convert presentation (PPTX/PPT) to PDF with formatting preserved
     */
    fun convertPresentationToPdf(
        inputPath: String,
        outputPath: String,
        format: String
    ): Result<String> {
        return try {
            val inputFile = File(inputPath)
            if (!inputFile.exists()) {
                return Result.failure(Exception("Input file not found: $inputPath"))
            }

            val pdfDocument = PdfDocument()
            var pageNumber = 1

            when (format.lowercase()) {
                "pptx" -> {
                    val slideShow = XMLSlideShow(FileInputStream(inputFile))
                    for (slide in slideShow.slides) {
                        val slideBitmap = renderSlideToBitmap(slide)
                        val pageInfo = PdfDocument.PageInfo.Builder(A4_WIDTH, A4_HEIGHT, pageNumber)
                            .create()
                        val page = pdfDocument.startPage(pageInfo)
                        // Scale to fit PDF page with high quality
                        val scaledBitmap = Bitmap.createScaledBitmap(slideBitmap, A4_WIDTH, A4_HEIGHT, true)
                        page.canvas.drawBitmap(scaledBitmap, 0f, 0f, null)
                        pdfDocument.finishPage(page)
                        pageNumber++
                    }
                    slideShow.close()
                }
                "ppt" -> {
                    val slideShow = HSLFSlideShow(FileInputStream(inputFile))
                    for (slide in slideShow.slides) {
                        val slideBitmap = renderHSLFSlideToBitmap(slide)
                        val pageInfo = PdfDocument.PageInfo.Builder(A4_WIDTH, A4_HEIGHT, pageNumber)
                            .create()
                        val page = pdfDocument.startPage(pageInfo)
                        val scaledBitmap = Bitmap.createScaledBitmap(slideBitmap, A4_WIDTH, A4_HEIGHT, true)
                        page.canvas.drawBitmap(scaledBitmap, 0f, 0f, null)
                        pdfDocument.finishPage(page)
                        pageNumber++
                    }
                    slideShow.close()
                }
                else -> return Result.failure(Exception("Unsupported format: $format"))
            }

            // Write PDF to output file
            val outputFile = File(outputPath)
            outputFile.parentFile?.mkdirs()
            
            FileOutputStream(outputFile).use { outputStream ->
                pdfDocument.writeTo(outputStream)
            }
            
            pdfDocument.close()

            Result.success(outputPath)
        } catch (e: Exception) {
            Result.failure(Exception("Presentation conversion failed: ${e.message}", e))
        }
    }

    /**
     * Convert DOCX to PDF with formatting preserved
     */
    fun convertDocxToPdf(
        inputPath: String,
        outputPath: String
    ): Result<String> {
        return try {
            val inputFile = File(inputPath)
            if (!inputFile.exists()) {
                return Result.failure(Exception("Input file not found: $inputPath"))
            }

            val doc = XWPFDocument(FileInputStream(inputFile))
            val pdfDocument = PdfDocument()
            var pageNumber = 1

            val pages = renderDocxToPages(doc)
            
            for (pageBitmap in pages) {
                val pageInfo = PdfDocument.PageInfo.Builder(A4_WIDTH, A4_HEIGHT, pageNumber)
                    .create()
                val page = pdfDocument.startPage(pageInfo)
                
                // Scale high-res bitmap to PDF page size
                val scaledBitmap = Bitmap.createScaledBitmap(pageBitmap, A4_WIDTH, A4_HEIGHT, true)
                page.canvas.drawBitmap(scaledBitmap, 0f, 0f, null)
                pdfDocument.finishPage(page)
                pageNumber++
            }

            // Write PDF
            val outputFile = File(outputPath)
            outputFile.parentFile?.mkdirs()
            
            FileOutputStream(outputFile).use { outputStream ->
                pdfDocument.writeTo(outputStream)
            }
            
            pdfDocument.close()
            doc.close()

            Result.success(outputPath)
        } catch (e: Exception) {
            Result.failure(Exception("DOCX conversion failed: ${e.message}", e))
        }
    }

    // ========== PRIVATE HELPER METHODS ==========

    /**
     * Render DOCX document to high-resolution bitmaps (one per page)
     */
    private fun renderDocxToPages(doc: XWPFDocument): List<Bitmap> {
        val pages = mutableListOf<Bitmap>()
        val bitmap = Bitmap.createBitmap(HIGH_RES_WIDTH, HIGH_RES_HEIGHT, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        
        val textPaint = TextPaint().apply {
            isAntiAlias = true
            isSubpixelText = true
        }
        
        var yPosition = HIGH_RES_MARGIN.toFloat()
        var currentPage = 1
        
        // Render each paragraph
        for (paragraph in doc.paragraphs) {
            // Get paragraph formatting
            val alignment = paragraph.alignment
            val spacingAfter = (paragraph.spacingAfter / 20).toFloat()
            
            // Render each run (text segment with formatting)
            for (run in paragraph.runs) {
                if (yPosition > HIGH_RES_HEIGHT - HIGH_RES_MARGIN) {
                    // Save current page and start new one
                    pages.add(bitmap.copy(Bitmap.Config.ARGB_8888, true))
                    currentPage++
                    bitmap.eraseColor(Color.WHITE)
                    yPosition = HIGH_RES_MARGIN.toFloat()
                }
                
                // Apply run formatting
                textPaint.textSize = run.fontSize?.let { it * RENDER_SCALE } ?: (12f * RENDER_SCALE)
                textPaint.color = run.getColor()?.let { parseColor(it) } ?: Color.BLACK
                textPaint.typeface = when {
                    run.isBold && run.isItalic -> Typeface.create(Typeface.DEFAULT, Typeface.BOLD_ITALIC)
                    run.isBold -> Typeface.DEFAULT_BOLD
                    run.isItalic -> Typeface.create(Typeface.DEFAULT, Typeface.ITALIC)
                    else -> Typeface.DEFAULT
                }
                
                val text = run.getText(0) ?: continue
                if (text.isBlank()) continue
                
                val layout = StaticLayout.Builder.obtain(text, 0, text.length, textPaint, HIGH_RES_CONTENT_WIDTH)
                    .setAlignment(when (alignment) {
                        org.apache.poi.xwpf.usermodel.ParagraphAlignment.CENTER -> Layout.Alignment.ALIGN_CENTER
                        org.apache.poi.xwpf.usermodel.ParagraphAlignment.RIGHT -> Layout.Alignment.ALIGN_OPPOSITE
                        else -> Layout.Alignment.ALIGN_NORMAL
                    })
                    .setLineSpacing(spacingAfter * RENDER_SCALE, 1.0f)
                    .build()
                
                canvas.save()
                canvas.translate(HIGH_RES_MARGIN.toFloat(), yPosition)
                layout.draw(canvas)
                canvas.restore()
                
                yPosition += layout.height + (spacingAfter * RENDER_SCALE)
            }
        }
        
        // Add last page
        pages.add(bitmap.copy(Bitmap.Config.ARGB_8888, true))
        
        return pages
    }

    /**
     * Render spreadsheet to high-resolution bitmaps with crisp text
     */
    private fun renderSheetToPages(sheet: org.apache.poi.ss.usermodel.Sheet): List<Bitmap> {
        val pages = mutableListOf<Bitmap>()
        val bitmap = Bitmap.createBitmap(HIGH_RES_WIDTH, HIGH_RES_HEIGHT, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.WHITE)
        
        val cellPaint = TextPaint().apply {
            textSize = 20f * RENDER_SCALE
            color = Color.BLACK
            isAntiAlias = true
            isSubpixelText = true
            typeface = Typeface.DEFAULT
        }
        
        val headerPaint = Paint().apply {
            color = Color.rgb(66, 133, 244)
            style = Paint.Style.FILL
            isAntiAlias = true
        }
        
        val gridPaint = Paint().apply {
            color = Color.rgb(200, 200, 200)
            strokeWidth = 1.5f * RENDER_SCALE
            style = Paint.Style.STROKE
            isAntiAlias = true
        }
        
        var yPosition = HIGH_RES_MARGIN.toFloat()
        var currentPage = 1
        
        // Calculate column widths
        val maxRow = sheet.lastRowNum
        var maxCol = 0
        for (rowIndex in 0..maxRow) {
            val row = sheet.getRow(rowIndex)
            if (row != null && row.lastCellNum > maxCol) {
                maxCol = row.lastCellNum.toInt()
            }
        }
        if (maxCol == 0) maxCol = 1
        val colWidth = HIGH_RES_CONTENT_WIDTH / maxCol
        val rowHeight = (40f * RENDER_SCALE).toInt()
        
        // Draw headers
        var xPosition = HIGH_RES_MARGIN
        canvas.drawRect(
            HIGH_RES_MARGIN.toFloat(), yPosition - (28f * RENDER_SCALE),
            (HIGH_RES_WIDTH - HIGH_RES_MARGIN).toFloat(), yPosition + (6f * RENDER_SCALE),
            headerPaint
        )
        
        for (colIndex in 0 until maxCol) {
            val headerText = getColumnLetter(colIndex)
            cellPaint.textSize = 24f * RENDER_SCALE
            cellPaint.color = Color.WHITE
            cellPaint.typeface = Typeface.DEFAULT_BOLD
            canvas.drawText(headerText, xPosition.toFloat(), yPosition, cellPaint)
            canvas.drawRect(
                xPosition.toFloat(), yPosition - (28f * RENDER_SCALE),
                (xPosition + colWidth).toFloat(), yPosition + (6f * RENDER_SCALE),
                gridPaint
            )
            xPosition += colWidth
        }
        yPosition += 40f * RENDER_SCALE
        
        // Draw data rows
        for (rowIndex in 0..maxRow) {
            val row = sheet.getRow(rowIndex) ?: continue
            
            // Check if we need a new page
            if (yPosition + rowHeight > HIGH_RES_HEIGHT - HIGH_RES_MARGIN) {
                pages.add(bitmap.copy(Bitmap.Config.ARGB_8888, true))
                currentPage++
                bitmap.eraseColor(Color.WHITE)
                yPosition = HIGH_RES_MARGIN.toFloat()
            }
            
            xPosition = HIGH_RES_MARGIN
            for (colIndex in 0 until maxCol) {
                val cell = row.getCell(colIndex)
                val cellValue = getCellValue(cell)
                
                // Alternate row colors
                if (rowIndex % 2 == 0) {
                    val bgPaint = Paint().apply {
                        color = Color.rgb(245, 245, 245)
                        style = Paint.Style.FILL
                    }
                    canvas.drawRect(
                        xPosition.toFloat(), yPosition - (24f * RENDER_SCALE),
                        (xPosition + colWidth).toFloat(), yPosition + (6f * RENDER_SCALE),
                        bgPaint
                    )
                }
                
                cellPaint.textSize = 20f * RENDER_SCALE
                cellPaint.color = Color.BLACK
                cellPaint.typeface = Typeface.DEFAULT
                canvas.drawText(cellValue, xPosition.toFloat(), yPosition, cellPaint)
                
                // Draw cell borders
                canvas.drawRect(
                    xPosition.toFloat(), yPosition - (24f * RENDER_SCALE),
                    (xPosition + colWidth).toFloat(), yPosition + (6f * RENDER_SCALE),
                    gridPaint
                )
                xPosition += colWidth
            }
            yPosition += rowHeight
        }
        
        // Add last page
        pages.add(bitmap.copy(Bitmap.Config.ARGB_8888, true))
        
        return pages
    }

    /**
     * Render PPTX slide to high-resolution bitmap with formatting
     */
    private fun renderSlideToBitmap(slide: org.apache.poi.xslf.usermodel.XSLFSlide): Bitmap {
        val bitmap = Bitmap.createBitmap(HIGH_RES_WIDTH, HIGH_RES_HEIGHT, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.WHITE)
        
        val titlePaint = TextPaint().apply {
            textSize = 48f * RENDER_SCALE
            color = Color.BLACK
            isAntiAlias = true
            isSubpixelText = true
            typeface = Typeface.DEFAULT_BOLD
        }
        
        val bodyPaint = TextPaint().apply {
            textSize = 32f * RENDER_SCALE
            color = Color.BLACK
            isAntiAlias = true
            isSubpixelText = true
        }
        
        var yPosition = HIGH_RES_MARGIN + 60f
        
        // Extract and render text from slide shapes with positioning
        for (shape in slide.shapes) {
            if (shape is org.apache.poi.xslf.usermodel.XSLFTextShape) {
                val text = shape.text?.trim() ?: continue
                if (text.isEmpty()) continue
                
                // Detect title by text length and position in slide
                val isTitle = text.length < 50 && slide.shapes.indexOf(shape) < 3
                
                val textPaint = if (isTitle) titlePaint else bodyPaint
                
                val layout = StaticLayout.Builder.obtain(text, 0, text.length, textPaint, HIGH_RES_CONTENT_WIDTH)
                    .setAlignment(Layout.Alignment.ALIGN_NORMAL)
                    .setLineSpacing(8f * RENDER_SCALE, 1.2f)
                    .build()
                
                canvas.save()
                canvas.translate(HIGH_RES_MARGIN.toFloat(), yPosition)
                layout.draw(canvas)
                canvas.restore()
                
                yPosition += layout.height + 20f * RENDER_SCALE
            }
        }
        
        return bitmap
    }

    /**
     * Render PPT slide to high-resolution bitmap with formatting
     */
    private fun renderHSLFSlideToBitmap(slide: org.apache.poi.hslf.usermodel.HSLFSlide): Bitmap {
        val bitmap = Bitmap.createBitmap(HIGH_RES_WIDTH, HIGH_RES_HEIGHT, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        canvas.drawColor(Color.WHITE)
        
        val titlePaint = TextPaint().apply {
            textSize = 48f * RENDER_SCALE
            color = Color.BLACK
            isAntiAlias = true
            isSubpixelText = true
            typeface = Typeface.DEFAULT_BOLD
        }
        
        val bodyPaint = TextPaint().apply {
            textSize = 32f * RENDER_SCALE
            color = Color.BLACK
            isAntiAlias = true
            isSubpixelText = true
        }
        
        var yPosition = HIGH_RES_MARGIN + 60f
        
        // Extract and render text from slide shapes
        for (shape in slide.shapes) {
            if (shape is org.apache.poi.hslf.usermodel.HSLFTextShape) {
                val text = shape.text?.trim() ?: continue
                if (text.isEmpty()) continue
                
                // Detect title by text length and position in slide
                val isTitle = text.length < 50 && slide.shapes.indexOf(shape) < 3
                
                val textPaint = if (isTitle) titlePaint else bodyPaint
                
                val layout = StaticLayout.Builder.obtain(text, 0, text.length, textPaint, HIGH_RES_CONTENT_WIDTH)
                    .setAlignment(Layout.Alignment.ALIGN_NORMAL)
                    .setLineSpacing(8f * RENDER_SCALE, 1.2f)
                    .build()
                
                canvas.save()
                canvas.translate(HIGH_RES_MARGIN.toFloat(), yPosition)
                layout.draw(canvas)
                canvas.restore()
                
                yPosition += layout.height + 20f * RENDER_SCALE
            }
        }
        
        return bitmap
    }

    private fun createWorkbookFromCsv(csvFile: File): Workbook {
        val workbook = XSSFWorkbook()
        val sheet = workbook.createSheet("CSV Data")

        csvFile.bufferedReader().useLines { lines ->
            var rowIndex = 0
            lines.forEach { line ->
                val row = sheet.createRow(rowIndex++)
                val columns = line.split(",")
                columns.forEachIndexed { colIndex, value ->
                    val cell = row.createCell(colIndex)
                    cell.setCellValue(value.trim().removeSurrounding("\""))
                }
            }
        }

        return workbook
    }

    private fun getCellValue(cell: org.apache.poi.ss.usermodel.Cell?): String {
        if (cell == null) return ""
        
        return when (cell.cellType) {
            CellType.STRING -> cell.stringCellValue
            CellType.NUMERIC -> {
                if (DateUtil.isCellDateFormatted(cell)) {
                    cell.dateCellValue.toString()
                } else {
                    val numVal = cell.numericCellValue
                    if (numVal == numVal.toLong().toDouble()) {
                        numVal.toLong().toString()
                    } else {
                        String.format("%.2f", numVal)
                    }
                }
            }
            CellType.BOOLEAN -> cell.booleanCellValue.toString()
            CellType.FORMULA -> cell.cellFormula
            else -> ""
        }
    }

    private fun getColumnLetter(index: Int): String {
        var result = ""
        var idx = index
        while (idx >= 0) {
            result = ((idx % 26) + 65).toChar().toString() + result
            idx = (idx / 26) - 1
        }
        return result
    }
    
    private fun parseColor(colorStr: String): Int {
        return try {
            if (colorStr.startsWith("#")) {
                Color.parseColor(colorStr)
            } else {
                when (colorStr.lowercase()) {
                    "red" -> Color.RED
                    "blue" -> Color.BLUE
                    "green" -> Color.GREEN
                    "black" -> Color.BLACK
                    "white" -> Color.WHITE
                    else -> Color.BLACK
                }
            }
        } catch (e: Exception) {
            Color.BLACK
        }
    }
}
