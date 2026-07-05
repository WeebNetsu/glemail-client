export const set_cookie = (key: string, value: string, expiryDate: string): boolean => {
    if (expiryDate.trim() !== '') {
        const newDate = new Date(expiryDate).toString();
        if (newDate === 'Invalid Date') return false;
        document.cookie = `${key}=${value}; expires=${new Date(expiryDate).toString()}`;
    } else {
        document.cookie = `${key}=${value}`;
    }

    return true;
};

export const get_cookies = (): string => {
    return document.cookie;
};

export const delete_cookie = (key: string): void => {
    // delete cookie by expiring it
    // https://www.w3schools.com/js/js_cookies.asp
    document.cookie = `${key}=; expires=Thu, 18 Dec 2013 12:00:00 UTC`;
};
