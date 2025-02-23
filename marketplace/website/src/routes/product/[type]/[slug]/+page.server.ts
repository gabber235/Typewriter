import { error } from '@sveltejs/kit';
import { products } from './products';
import type { PageServerLoad } from './$types';

export const load: PageServerLoad = ({ params }) => {
    const product = products.find((product) => product.slug === params.slug && product.type === params.type);

    if (!product) throw error(404, 'Product not found');

    return {
        product
    };
};