#include "calculator_engine.h"

#include <cmath>
#include <iomanip>
#include <sstream>

namespace calculator
{

Engine::Engine()
{
    clear();
}

void Engine::press(char key)
{
    if (key == 'c')
        key = 'C';
    else if (key == '\r' || key == '\n')
        key = '=';

    if (key == 'C')
    {
        clear();
        return;
    }

    if (errorState)
        return;

    if (key >= '0' && key <= '9')
        inputDigit(key);
    else if (key == '.')
        inputDecimalPoint();
    else if (key == '+' || key == '-' || key == '*' || key == '/')
        selectOperator(key);
    else if (key == '=')
        calculateResult();
}

void Engine::clear()
{
    entry = "0";
    accumulator = 0;
    pendingOperator = '\0';
    enteringNumber = false;
    resultShown = false;
    errorState = false;
}

const std::string &Engine::display() const noexcept
{
    return entry;
}

bool Engine::hasError() const noexcept
{
    return errorState;
}

void Engine::inputDigit(char digit)
{
    beginFreshEntryIfNeeded();

    if (!enteringNumber)
    {
        entry = "0";
        enteringNumber = true;
    }

    if (entry == "0")
        entry.assign(1, digit);
    else if (entry.size() < maxEntryLength)
        entry.push_back(digit);
}

void Engine::inputDecimalPoint()
{
    beginFreshEntryIfNeeded();

    if (!enteringNumber)
    {
        entry = "0";
        enteringNumber = true;
    }

    if (entry.find('.') == std::string::npos && entry.size() < maxEntryLength)
        entry.push_back('.');
}

void Engine::selectOperator(char operation)
{
    const long double value = currentValue();

    if (pendingOperator != '\0' && enteringNumber)
    {
        if (!applyPending(value))
            return;
    }
    else if (pendingOperator == '\0')
        accumulator = value;

    pendingOperator = operation;
    enteringNumber = false;
    resultShown = false;
    showValue(accumulator);
}

void Engine::calculateResult()
{
    if (pendingOperator == '\0' || !enteringNumber)
        return;

    if (!applyPending(currentValue()))
        return;

    pendingOperator = '\0';
    enteringNumber = false;
    resultShown = true;
    showValue(accumulator);
}

bool Engine::applyPending(long double rightOperand)
{
    switch (pendingOperator)
    {
        case '+':
            accumulator += rightOperand;
            break;
        case '-':
            accumulator -= rightOperand;
            break;
        case '*':
            accumulator *= rightOperand;
            break;
        case '/':
            if (rightOperand == 0)
            {
                setError();
                return false;
            }
            accumulator /= rightOperand;
            break;
        default:
            accumulator = rightOperand;
            break;
    }

    if (!std::isfinite(accumulator))
    {
        setError();
        return false;
    }

    showValue(accumulator);
    return true;
}

void Engine::beginFreshEntryIfNeeded()
{
    if (resultShown && pendingOperator == '\0')
    {
        accumulator = 0;
        entry = "0";
        resultShown = false;
        enteringNumber = false;
    }
}

void Engine::setError()
{
    entry = "Error";
    accumulator = 0;
    pendingOperator = '\0';
    enteringNumber = false;
    resultShown = false;
    errorState = true;
}

long double Engine::currentValue() const
{
    return std::stold(entry);
}

void Engine::showValue(long double value)
{
    entry = formatValue(value);
}

std::string Engine::formatValue(long double value)
{
    if (std::fabs(value) < 1e-12L)
        value = 0;

    std::ostringstream stream;
    stream << std::setprecision(12) << std::defaultfloat << value;
    std::string text = stream.str();

    const std::size_t exponent = text.find_first_of("eE");
    if (exponent == std::string::npos)
    {
        const std::size_t decimalPoint = text.find('.');
        if (decimalPoint != std::string::npos)
        {
            while (!text.empty() && text.back() == '0')
                text.pop_back();
            if (!text.empty() && text.back() == '.')
                text.pop_back();
        }
    }

    return text.empty() || text == "-0" ? "0" : text;
}

} // namespace calculator
