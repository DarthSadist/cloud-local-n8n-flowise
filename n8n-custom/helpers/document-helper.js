/**
 * Хелпер для работы с документами в n8n
 * Упрощает работу с PDF, Excel, Word и другими форматами документов
 */

const { PDFDocument } = require('pdf-lib');
const pdfParse = require('pdf-parse');
const xlsx = require('xlsx');
const ExcelJS = require('exceljs');
const mammoth = require('mammoth');
const htmlPdf = require('html-pdf');
const libreoffice = require('@shelf/aws-lambda-libreoffice');
const fs = require('fs');
const path = require('path');
const os = require('os');

class DocumentHelper {
  /**
   * Создает экземпляр хелпера для работы с документами
   */
  constructor() {
    // Создаем временную директорию для работы с файлами
    this.tempDir = path.join(os.tmpdir(), 'n8n-document-helper');
    if (!fs.existsSync(this.tempDir)) {
      fs.mkdirSync(this.tempDir, { recursive: true });
    }
  }

  /**
   * Извлечение текста из PDF-документа
   * @param {Buffer|string} input - Буфер с PDF или путь к файлу
   * @returns {Promise<string>} - Извлеченный текст
   */
  async extractTextFromPdf(input) {
    try {
      const buffer = this._getBuffer(input);
      const data = await pdfParse(buffer);
      return data.text;
    } catch (error) {
      console.error('Error extracting text from PDF:', error);
      throw error;
    }
  }

  /**
   * Создание нового PDF-документа
   * @param {Object} options - Параметры создания
   * @param {string} options.text - Текст для добавления в PDF
   * @param {Array<Buffer>} options.images - Массив буферов с изображениями для добавления
   * @returns {Promise<Buffer>} - Буфер с созданным PDF
   */
  async createPdf(options = {}) {
    try {
      const pdfDoc = await PDFDocument.create();
      const page = pdfDoc.addPage([595, 842]); // A4 размер
      
      if (options.text) {
        page.drawText(options.text, {
          x: 50,
          y: 750,
          size: 12
        });
      }
      
      // Если есть изображения, добавляем их
      if (options.images && Array.isArray(options.images)) {
        let yPosition = 700;
        for (const imgBuffer of options.images) {
          try {
            let image;
            if (imgBuffer.toString('ascii', 0, 4) === '%PDF') {
              // Это PDF, нужно обработать по-другому
              continue;
            } else if (imgBuffer[0] === 0xff && imgBuffer[1] === 0xd8) {
              // JPEG
              image = await pdfDoc.embedJpg(imgBuffer);
            } else {
              // PNG и другие
              image = await pdfDoc.embedPng(imgBuffer);
            }
            
            const { width, height } = image.scale(0.5);
            page.drawImage(image, {
              x: 50,
              y: yPosition - height,
              width,
              height
            });
            
            yPosition -= (height + 20);
          } catch (imgError) {
            console.error('Error embedding image:', imgError);
          }
        }
      }
      
      return await pdfDoc.save();
    } catch (error) {
      console.error('Error creating PDF:', error);
      throw error;
    }
  }

  /**
   * Объединение нескольких PDF-документов в один
   * @param {Array<Buffer|string>} inputs - Массив буферов с PDF или путей к файлам
   * @returns {Promise<Buffer>} - Буфер с объединенным PDF
   */
  async mergePdfs(inputs) {
    try {
      const mergedPdf = await PDFDocument.create();
      
      for (const input of inputs) {
        const buffer = this._getBuffer(input);
        const pdf = await PDFDocument.load(buffer);
        const copiedPages = await mergedPdf.copyPages(pdf, pdf.getPageIndices());
        copiedPages.forEach(page => mergedPdf.addPage(page));
      }
      
      return await mergedPdf.save();
    } catch (error) {
      console.error('Error merging PDFs:', error);
      throw error;
    }
  }

  /**
   * Чтение данных из Excel-файла
   * @param {Buffer|string} input - Буфер с Excel или путь к файлу
   * @param {Object} options - Параметры чтения
   * @param {string} options.sheet - Имя листа (опционально)
   * @param {boolean} options.header - Использовать первую строку как заголовки
   * @returns {Promise<Array>} - Массив с данными из Excel
   */
  async readExcel(input, options = {}) {
    try {
      const buffer = this._getBuffer(input);
      const workbook = xlsx.read(buffer, { type: 'buffer' });
      
      const sheetName = options.sheet || workbook.SheetNames[0];
      const sheet = workbook.Sheets[sheetName];
      
      return xlsx.utils.sheet_to_json(sheet, {
        header: options.header ? 1 : undefined,
        raw: true
      });
    } catch (error) {
      console.error('Error reading Excel:', error);
      throw error;
    }
  }

  /**
   * Создание Excel-файла
   * @param {Array} data - Массив данных для записи
   * @param {Object} options - Параметры создания
   * @param {string} options.sheet - Имя листа
   * @returns {Promise<Buffer>} - Буфер с созданным Excel-файлом
   */
  async createExcel(data, options = {}) {
    try {
      const workbook = new ExcelJS.Workbook();
      const sheetName = options.sheet || 'Sheet1';
      const sheet = workbook.addWorksheet(sheetName);
      
      // Если данные - массив объектов, извлекаем заголовки
      if (data.length > 0 && typeof data[0] === 'object') {
        const headers = Object.keys(data[0]);
        sheet.addRow(headers);
        
        // Добавляем данные
        data.forEach(row => {
          sheet.addRow(Object.values(row));
        });
      } else {
        // Просто добавляем строки
        data.forEach(row => {
          sheet.addRow(Array.isArray(row) ? row : [row]);
        });
      }
      
      // Применяем стили к заголовкам
      if (data.length > 0 && typeof data[0] === 'object') {
        const headerRow = sheet.getRow(1);
        headerRow.font = { bold: true };
        headerRow.fill = {
          type: 'pattern',
          pattern: 'solid',
          fgColor: { argb: 'FFE0E0E0' }
        };
      }
      
      // Автоматическая ширина столбцов
      sheet.columns.forEach(column => {
        column.width = 15;
      });
      
      return await workbook.xlsx.writeBuffer();
    } catch (error) {
      console.error('Error creating Excel:', error);
      throw error;
    }
  }

  /**
   * Преобразование DOCX в HTML
   * @param {Buffer|string} input - Буфер с DOCX или путь к файлу
   * @returns {Promise<string>} - HTML-представление документа
   */
  async docxToHtml(input) {
    try {
      const buffer = this._getBuffer(input);
      const result = await mammoth.convertToHtml({ buffer });
      return result.value;
    } catch (error) {
      console.error('Error converting DOCX to HTML:', error);
      throw error;
    }
  }

  /**
   * Преобразование DOCX в текст
   * @param {Buffer|string} input - Буфер с DOCX или путь к файлу
   * @returns {Promise<string>} - Текстовое представление документа
   */
  async docxToText(input) {
    try {
      const buffer = this._getBuffer(input);
      const result = await mammoth.extractRawText({ buffer });
      return result.value;
    } catch (error) {
      console.error('Error converting DOCX to text:', error);
      throw error;
    }
  }

  /**
   * Преобразование HTML в PDF
   * @param {string} html - HTML-строка
   * @param {Object} options - Параметры создания PDF
   * @returns {Promise<Buffer>} - Буфер с созданным PDF
   */
  async htmlToPdf(html, options = {}) {
    try {
      const defaultOptions = {
        format: 'A4',
        border: {
          top: '20mm',
          right: '20mm',
          bottom: '20mm',
          left: '20mm'
        }
      };
      
      const pdfOptions = { ...defaultOptions, ...options };
      
      return new Promise((resolve, reject) => {
        htmlPdf.create(html, pdfOptions).toBuffer((err, buffer) => {
          if (err) {
            reject(err);
            return;
          }
          resolve(buffer);
        });
      });
    } catch (error) {
      console.error('Error converting HTML to PDF:', error);
      throw error;
    }
  }

  /**
   * Конвертация офисных документов с помощью LibreOffice
   * @param {Buffer|string} input - Буфер с документом или путь к файлу
   * @param {string} outputFormat - Формат вывода (pdf, html, txt)
   * @returns {Promise<Buffer>} - Буфер с конвертированным документом
   */
  async convertOfficeDocument(input, outputFormat = 'pdf') {
    try {
      const buffer = this._getBuffer(input);
      const tempInput = path.join(this.tempDir, 'input_document');
      fs.writeFileSync(tempInput, buffer);
      
      // Определяем формат для LibreOffice
      let format;
      switch (outputFormat.toLowerCase()) {
        case 'pdf':
          format = 'pdf';
          break;
        case 'html':
          format = 'html';
          break;
        case 'txt':
          format = 'txt';
          break;
        default:
          format = 'pdf';
      }
      
      // Конвертируем с помощью LibreOffice
      const outputPath = await libreoffice.convert({
        inputFile: tempInput,
        outputFormat: format,
        timeout: 30000 // 30 секунд
      });
      
      const result = fs.readFileSync(outputPath);
      
      // Удаляем временные файлы
      try {
        fs.unlinkSync(tempInput);
        fs.unlinkSync(outputPath);
      } catch (e) {
        console.error('Error cleaning up temp files:', e);
      }
      
      return result;
    } catch (error) {
      console.error('Error converting office document:', error);
      throw error;
    }
  }

  /**
   * Получает буфер из входных данных
   * @param {Buffer|string} input - Буфер с документом или путь к файлу
   * @returns {Buffer} - Буфер с документом
   * @private
   */
  _getBuffer(input) {
    if (Buffer.isBuffer(input)) {
      return input;
    }
    
    if (typeof input === 'string') {
      return fs.readFileSync(input);
    }
    
    throw new Error('Input must be a buffer or a file path');
  }
}

module.exports = DocumentHelper;
