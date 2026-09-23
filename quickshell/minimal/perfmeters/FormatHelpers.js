// FormatHelpers.js
// GPL-3.0 license
.pragma library

/**
 * Universal Type-Agnostic Number Scaler
 * @param {number} value - The raw input number to format (bytes, bits, bytes/sec, etc.)
 * @param {number} targetDigits - Total length of digits to display (e.g., 2 or 3)
 * @return {string} Scaled number coupled with its pure unit suffix (e.g., "9.5 M" or "105 K")
 */
function formatUnits(value, targetDigits) {
    let num = parseFloat(value);
    // Safety guard protects engine from NaN or negative boundaries
    if (isNaN(num) || num <= 0) {
        return "0";
    }

    // Determine the mathematical unit bracket threshold natively
    let unit = "";
    if (num >= 1099511627776) { num /= 1099511627776; unit = " T"; }
    else if (num >= 1073741824) { num /= 1073741824; unit = " G"; }
    else if (num >= 1048576)    { num /= 1048576;    unit = " M"; }
    else if (num >= 1024)       { num /= 1024;       unit = " K"; }

    // DYNAMIC PRECISION ENGINE: Calculate how many decimal places 
    // are needed to satisfy your exact target length parameter constraint.
    let digitsBeforeDecimal = Math.floor(num).toString().length;
    let allowedDecimals = Math.max(0, targetDigits - digitsBeforeDecimal);

    // Format the number and strip out any ugly trailing zeroes (like 12.0 -> 12)
    let formattedNum = num.toFixed(allowedDecimals);
    if (formattedNum.indexOf(".") !== -1) {
        // Strip out trailing zeros after a decimal point, and drop the period if empty
        formattedNum = formattedNum.replace(/\.?0+$/, "");
    }

    return formattedNum + unit;
}

