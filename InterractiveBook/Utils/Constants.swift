import Foundation

enum Constants {
    static let epubCustomCSS = """
        body {
            font-family: -apple-system, system-ui, sans-serif;
            line-height: 1.6;
            padding: 20px;
            max-width: 800px;
            margin: 0 auto;
            font-size: 16px;
            color: #333;
            background-color: #fff;
            transition: all 0.3s ease;
        }
        
        .night-mode {
            background-color: #1a1a1a !important;
            color: #e0e0e0 !important;
        }
        
        .night-mode a {
            color: #4da6ff !important;
        }
        
        img {
            max-width: 100%;
            height: auto;
            display: block;
            margin: 20px auto;
        }
        
        h1, h2, h3, h4, h5, h6 {
            margin-top: 1.5em;
            margin-bottom: 0.5em;
            line-height: 1.2;
        }
        
        p {
            margin-bottom: 1em;
            text-align: justify;
        }
        
        .interactive-button {
            background-color: #007AFF;
            color: white;
            padding: 12px 20px;
            border-radius: 10px;
            border: none;
            cursor: pointer;
            margin: 15px 0;
            font-size: 16px;
            font-weight: 500;
            display: inline-block;
            text-align: center;
            transition: background-color 0.2s;
            box-shadow: 0 2px 4px rgba(0, 0, 0, 0.1);
        }
        
        .interactive-button:hover {
            background-color: #0056CC;
            transform: translateY(-1px);
            box-shadow: 0 4px 8px rgba(0, 0, 0, 0.15);
        }
        
        .interactive-button:active {
            transform: translateY(0);
            box-shadow: 0 1px 2px rgba(0, 0, 0, 0.1);
        }
        
        .choice-container {
            background-color: #f5f5f5;
            border-left: 4px solid #007AFF;
            padding: 15px;
            margin: 20px 0;
            border-radius: 0 8px 8px 0;
        }
        
        .night-mode .choice-container {
            background-color: #2a2a2a;
            border-left-color: #4da6ff;
        }
        
        .dice-roll {
            background-color: #e8f4ff;
            border: 2px dashed #007AFF;
            padding: 10px;
            margin: 15px 0;
            border-radius: 8px;
            font-family: 'Courier New', monospace;
        }
        
        .night-mode .dice-roll {
            background-color: #2a3a4a;
            border-color: #4da6ff;
        }
        
        blockquote {
            border-left: 4px solid #ccc;
            margin: 20px 0;
            padding-left: 20px;
            font-style: italic;
            color: #666;
        }
        
        .night-mode blockquote {
            border-left-color: #666;
            color: #aaa;
        }
        
        a {
            color: #007AFF;
            text-decoration: none;
        }
        
        a:hover {
            text-decoration: underline;
        }
        
        table {
            border-collapse: collapse;
            width: 100%;
            margin: 20px 0;
        }
        
        th, td {
            border: 1px solid #ddd;
            padding: 12px;
            text-align: left;
        }
        
        th {
            background-color: #f2f2f2;
            font-weight: bold;
        }
        
        .night-mode th {
            background-color: #333;
        }
        
        .night-mode td {
            border-color: #444;
        }
        
        code {
            background-color: #f5f5f5;
            padding: 2px 4px;
            border-radius: 4px;
            font-family: 'Courier New', monospace;
            font-size: 14px;
        }
        
        .night-mode code {
            background-color: #333;
        }
        
        pre {
            background-color: #f5f5f5;
            padding: 15px;
            border-radius: 8px;
            overflow-x: auto;
            margin: 20px 0;
        }
        
        .night-mode pre {
            background-color: #2a2a2a;
        }
        
        /* Улучшения для мобильных устройств */
        @media (max-width: 768px) {
            body {
                padding: 15px;
                font-size: 15px;
            }
            
            .interactive-button {
                width: 100%;
                padding: 15px;
            }
            
            h1 {
                font-size: 1.8em;
            }
            
            h2 {
                font-size: 1.5em;
            }
        }
        """
    
    static let javaScriptBridge = """
        window.InteractiveBookBridge = {
            // Основные функции
            rollDice: function(formula, context) {
                window.webkit.messageHandlers.bookHandler.postMessage({
                    type: 'rollDice',
                    data: { 
                        formula: formula,
                        context: context || 'Из книги'
                    }
                });
            },
            
            showCharacterSheet: function() {
                window.webkit.messageHandlers.bookHandler.postMessage({
                    type: 'showCharacterSheet',
                    data: {}
                });
            },
            
            updateCharacterStat: function(statName, value) {
                window.webkit.messageHandlers.bookHandler.postMessage({
                    type: 'updateCharacter',
                    data: { 
                        stat: statName,
                        value: parseInt(value)
                    }
                });
            },
            
            saveChoice: function(choiceId, selectedOption) {
                window.webkit.messageHandlers.bookHandler.postMessage({
                    type: 'saveChoice',
                    data: { 
                        choiceId: choiceId,
                        option: selectedOption
                    }
                });
            },
            
            navigateToPage: function(pageUrl) {
                window.webkit.messageHandlers.bookHandler.postMessage({
                    type: 'navigateToPage',
                    data: { 
                        url: pageUrl
                    }
                });
            },
            
            // Вспомогательные функции
            getChoice: function(choiceId) {
                // Возвращает сохраненный выбор из локального хранилища
                return localStorage.getItem('choice_' + choiceId);
            },
            
            hasChoice: function(choiceId) {
                // Проверяет, был ли сделан выбор
                return localStorage.getItem('choice_' + choiceId) !== null;
            },
            
            setStyle: function(property, value) {
                // Устанавливает стиль для всего документа
                document.documentElement.style.setProperty(property, value);
            },
            
            toggleNightMode: function() {
                // Переключает ночной режим
                document.body.classList.toggle('night-mode');
                localStorage.setItem('nightMode', document.body.classList.contains('night-mode'));
            },
            
            setFontSize: function(size) {
                // Устанавливает размер шрифта
                document.body.style.fontSize = size + 'px';
                localStorage.setItem('fontSize', size);
            },
            
            // Инициализация
            initialize: function() {
                // Восстанавливаем настройки
                var nightMode = localStorage.getItem('nightMode') === 'true';
                if (nightMode) {
                    document.body.classList.add('night-mode');
                }
                
                var fontSize = localStorage.getItem('fontSize');
                if (fontSize) {
                    document.body.style.fontSize = fontSize + 'px';
                }
                
                console.log('Interactive Book Bridge initialized');
            },
            
            // Утилиты для работы с кубиками
            parseDiceFormula: function(formula) {
                var match = formula.match(/^(\\d+)d(\\d+)([+-]\\d+)?$/);
                if (!match) return null;
                
                return {
                    dice: parseInt(match[1]),
                    sides: parseInt(match[2]),
                    modifier: match[3] ? parseInt(match[3]) : 0
                };
            },
            
            // Генерация случайного числа в диапазоне
            randomInt: function(min, max) {
                return Math.floor(Math.random() * (max - min + 1)) + min;
            }
        };
        
        // Автоматическая инициализация при загрузке страницы
        document.addEventListener('DOMContentLoaded', function() {
            InteractiveBookBridge.initialize();
            
            // Добавляем обработчики для всех интерактивных кнопок
            document.querySelectorAll('[data-dice-roll]').forEach(function(button) {
                button.addEventListener('click', function() {
                    var formula = this.getAttribute('data-dice-roll');
                    var context = this.getAttribute('data-context') || 'Из книги';
                    InteractiveBookBridge.rollDice(formula, context);
                });
            });
            
            // Обработчики для выбора вариантов
            document.querySelectorAll('[data-choice]').forEach(function(button) {
                button.addEventListener('click', function() {
                    var choiceId = this.getAttribute('data-choice-id');
                    var option = this.getAttribute('data-choice-option');
                    InteractiveBookBridge.saveChoice(choiceId, option);
                    
                    // Показываем результат выбора
                    var resultElement = document.querySelector('[data-choice-result="' + choiceId + '"]');
                    if (resultElement) {
                        resultElement.style.display = 'block';
                    }
                });
            });
            
            // Обработчики для ссылок на персонажа
            document.querySelectorAll('[data-character-stat]').forEach(function(element) {
                element.addEventListener('click', function() {
                    var stat = this.getAttribute('data-character-stat');
                    InteractiveBookBridge.showCharacterSheet();
                });
            });
        });
        
        // Добавляем стили для интерактивных элементов
        var style = document.createElement('style');
        style.textContent = `
            [data-dice-roll] {
                cursor: pointer;
            }
            
            [data-choice] {
                margin: 5px;
                padding: 8px 16px;
                border-radius: 6px;
                border: 2px solid #007AFF;
                background: white;
                color: #007AFF;
                cursor: pointer;
                transition: all 0.2s;
            }
            
            [data-choice]:hover {
                background: #007AFF;
                color: white;
            }
            
            [data-choice-result] {
                display: none;
                margin-top: 10px;
                padding: 10px;
                background: #f0f8ff;
                border-radius: 6px;
                border-left: 4px solid #007AFF;
            }
            
            .dice-result {
                font-weight: bold;
                color: #007AFF;
                font-family: monospace;
            }
        `;
        document.head.appendChild(style);
        
        // Делаем bridge глобально доступным
        window.epubBridge = window.InteractiveBookBridge;
        """
}
