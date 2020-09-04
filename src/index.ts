import { handlerHello } from './hello';

// eslint-disable-next-line @typescript-eslint/ban-ts-ignore
// @ts-ignore
export async function handler(event: any, context: any, callback: any) {
    switch (event.resolve) {
        case 'hello':
            callback(null, handlerHello());
            break;
        default:
            callback('Error: no resolver found', null);
    }
}
